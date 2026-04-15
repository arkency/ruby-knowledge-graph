require "rails_helper"

RSpec.describe BuildKnowledgeGraph do
  subject(:handler) { described_class.new }

  def create_ingestion(id = SecureRandom.uuid)
    Ingestion.create!(id: id, content_hash: SecureRandom.hex(16))
    id
  end

  def build_event(ingestion_id: create_ingestion, **data)
    extraction = Extraction.create!(
      ingestion_id: ingestion_id,
      status: "started"
    )
    KnowledgeExtracted.new(
      data: { extraction_id: extraction.id, ingestion_id: ingestion_id, **data }
    )
  end

  let(:ingestion_id) { create_ingestion }

  let(:event) do
    build_event(
      ingestion_id: ingestion_id,
      title: "Test meeting",
      summary: "A test meeting discussion",
      nodes: [
        { name: "Acme Corp", kind: "company", description: "Ruby consultancy" },
        { name: "Alice Johnson", kind: "person", description: "CEO", attrs: [ { key: "role", value: "CEO" } ] },
        { name: "Rails Event Store", kind: "project", description: "Event sourcing for Rails" },
        { name: "RES roadmap", kind: "topic", description: "Discussion about RES future" }
      ],
      edges: [
        { source: "Alice Johnson", target: "Acme Corp", relation: "works_at", context: "CEO of Acme Corp" },
        { source: "Alice Johnson", target: "RES roadmap", relation: "discussed_in", context: "Led the discussion" },
        { source: "RES roadmap", target: "Rails Event Store", relation: "contains", context: "Topic about RES" }
      ]
    )
  end

  it "creates nodes from event data" do
    handler.call(event)

    expect(Node.count).to eq(4)
    expect(Node.find_by(slug: "acme-corp").kind).to eq("company")
    expect(Node.find_by(slug: "alice-johnson").attrs).to eq({ "role" => "CEO" })
  end

  it "creates edges between nodes" do
    handler.call(event)

    expect(Edge.count).to eq(3)
    edge = Edge.joins(:source_node, :target_node)
      .where(source_node: { slug: "alice-johnson" }, target_node: { slug: "acme-corp" })
      .first
    expect(edge.relation).to eq("works_at")
  end

  it "upserts nodes on duplicate slug" do
    handler.call(event)

    updated_event = build_event(
      content_hash: "def456",
      title: "Another meeting",
      summary: "Another discussion",
      nodes: [
        { name: "Acme Corp", kind: "company", description: "Updated description" }
      ],
      edges: []
    )

    handler.call(updated_event)

    expect(Node.where(slug: "acme-corp").count).to eq(1)
    expect(Node.find_by(slug: "acme-corp").description).to eq("Updated description")
  end

  it "upserts edges on duplicate triple" do
    handler.call(event)

    updated_event = build_event(
      content_hash: "def456",
      title: "Another meeting",
      summary: "Updated",
      nodes: [
        { name: "Alice Johnson", kind: "person", description: "CEO" },
        { name: "Acme Corp", kind: "company", description: "Ruby consultancy" }
      ],
      edges: [
        { source: "Alice Johnson", target: "Acme Corp", relation: "works_at", context: "Updated context" }
      ]
    )

    handler.call(updated_event)

    edges = Edge.joins(:source_node, :target_node)
      .where(source_node: { slug: "alice-johnson" }, target_node: { slug: "acme-corp" }, relation: "works_at")
    expect(edges.count).to eq(1)
    expect(edges.first.context).to eq("Updated context")
  end

  it "stores and merges edge attrs" do
    event_with_attrs = build_event(
      content_hash: "attrs1",
      title: "Test",
      summary: "Test",
      nodes: [
        { name: "Alice Johnson", kind: "person", description: "CEO" },
        { name: "Acme Corp", kind: "company", description: "Ruby consultancy" }
      ],
      edges: [
        { source: "Alice Johnson", target: "Acme Corp", relation: "works_at", context: "CEO", attrs: [ { key: "since", value: "2006" } ] }
      ]
    )

    handler.call(event_with_attrs)

    edge = Edge.joins(:source_node, :target_node)
      .where(source_node: { slug: "alice-johnson" }, target_node: { slug: "acme-corp" })
      .first
    expect(edge.attrs).to eq({ "since" => "2006" })

    # Second call merges attrs
    update_event = build_event(
      content_hash: "attrs2",
      title: "Test",
      summary: "Test",
      nodes: [
        { name: "Alice Johnson", kind: "person", description: "CEO" },
        { name: "Acme Corp", kind: "company", description: "Ruby consultancy" }
      ],
      edges: [
        { source: "Alice Johnson", target: "Acme Corp", relation: "works_at", context: "CEO", attrs: [ { key: "role", value: "founder" } ] }
      ]
    )

    handler.call(update_event)

    edge.reload
    expect(edge.attrs).to eq({ "since" => "2006", "role" => "founder" })
  end

  it "marks node_extraction as create on first occurrence" do
    handler.call(event)

    ne = NodeExtraction.joins(:node).find_by(nodes: { slug: "acme-corp" })
    expect(ne.kind).to eq("create")
    expect(ne.diff.keys).to include("slug", "name", "kind")
  end

  it "marks edge_extraction as create on first occurrence" do
    handler.call(event)

    edge = Edge.joins(:source_node, :target_node)
      .where(source_node: { slug: "alice-johnson" }, target_node: { slug: "acme-corp" })
      .first
    ee = EdgeExtraction.find_by(edge: edge)
    expect(ee.kind).to eq("create")
  end

  it "records diff and kind=update on node_extractions when node is updated" do
    handler.call(event)

    updated_event = build_event(
      content_hash: "diff_test",
      title: "Diff test",
      summary: "Testing diff",
      nodes: [
        { name: "Acme Corp", kind: "company", description: "Updated Ruby consultancy" }
      ],
      edges: []
    )

    handler.call(updated_event)

    second_extraction = Extraction.find(updated_event.data[:extraction_id])
    ne = NodeExtraction.joins(:node).find_by(nodes: { slug: "acme-corp" }, extraction: second_extraction)
    expect(ne.kind).to eq("update")
    expect(ne.diff).to include("description" => [ "Ruby consultancy", "Updated Ruby consultancy" ])
  end

  it "records diff and kind=update on edge_extractions when edge is updated" do
    handler.call(event)

    updated_event = build_event(
      content_hash: "edge_diff",
      title: "Edge diff",
      summary: "Testing edge diff",
      nodes: [
        { name: "Alice Johnson", kind: "person", description: "CEO" },
        { name: "Acme Corp", kind: "company", description: "Ruby consultancy" }
      ],
      edges: [
        { source: "Alice Johnson", target: "Acme Corp", relation: "works_at", context: "Updated context" }
      ]
    )

    handler.call(updated_event)

    edge = Edge.joins(:source_node, :target_node)
      .where(source_node: { slug: "alice-johnson" }, target_node: { slug: "acme-corp" })
      .first
    second_extraction = Extraction.find(updated_event.data[:extraction_id])
    ee = EdgeExtraction.find_by(edge: edge, extraction: second_extraction)
    expect(ee.kind).to eq("update")
    expect(ee.diff).to include("context" => [ "CEO of Acme Corp", "Updated context" ])
  end

  describe "read_set persistence" do
    let!(:acme_corp) { Node.create!(slug: "acme-corp", name: "Acme Corp", kind: "company") }
    let!(:alice) { Node.create!(slug: "alice-johnson", name: "Alice Johnson", kind: "person") }
    let!(:works_at_edge) do
      Edge.create!(source_node: alice, target_node: acme_corp, relation: "works_at")
    end

    it "creates node_extraction_reads from extraction.read_set" do
      event_with_reads = build_event(
        content_hash: "reads1",
        title: "Test",
        summary: "Test",
        nodes: [],
        edges: [],
        extraction: {
          read_set: [
            { node_id: acme_corp.id, tools: [ "search_nodes" ] },
            { node_id: alice.id, tools: [ "search_nodes", "list_nodes_by_kind" ] }
          ]
        }
      )

      handler.call(event_with_reads)

      reads = NodeExtractionRead.where(extraction_id: event_with_reads.data[:extraction_id])
      expect(reads.count).to eq(2)
      expect(reads.find_by(node: acme_corp).tools).to eq([ "search_nodes" ])
      expect(reads.find_by(node: alice).tools).to match_array([ "search_nodes", "list_nodes_by_kind" ])
    end

    it "creates edge_extraction_reads from extraction.edge_reads ids" do
      event_with_reads = build_event(
        content_hash: "reads2",
        title: "Test",
        summary: "Test",
        nodes: [],
        edges: [],
        extraction: {
          read_set: [
            { node_id: acme_corp.id, tools: [ "get_node_edges" ] }
          ],
          edge_reads: [ works_at_edge.id ]
        }
      )

      handler.call(event_with_reads)

      reads = EdgeExtractionRead.where(extraction_id: event_with_reads.data[:extraction_id])
      expect(reads.count).to eq(1)
      expect(reads.first.edge).to eq(works_at_edge)
    end

    it "does not create edge_extraction_reads when edge_reads is empty" do
      event_with_reads = build_event(
        content_hash: "reads3",
        title: "Test",
        summary: "Test",
        nodes: [],
        edges: [],
        extraction: {
          read_set: [
            { node_id: acme_corp.id, tools: [ "search_nodes" ] }
          ]
        }
      )

      handler.call(event_with_reads)

      expect(EdgeExtractionRead.count).to eq(0)
    end

    it "skips edge_reads ids that do not match an existing edge" do
      event_with_reads = build_event(
        content_hash: "reads3b",
        title: "Test",
        summary: "Test",
        nodes: [],
        edges: [],
        extraction: {
          read_set: [],
          edge_reads: [ SecureRandom.uuid, SecureRandom.uuid ]
        }
      )

      handler.call(event_with_reads)

      expect(EdgeExtractionRead.count).to eq(0)
    end

    it "skips read_set entries for unknown node ids" do
      event_with_reads = build_event(
        content_hash: "reads4",
        title: "Test",
        summary: "Test",
        nodes: [],
        edges: [],
        extraction: {
          read_set: [
            { node_id: SecureRandom.uuid, tools: [ "search_nodes" ] }
          ]
        }
      )

      expect { handler.call(event_with_reads) }.not_to raise_error
      expect(NodeExtractionRead.count).to eq(0)
    end

    it "is idempotent on replay" do
      event_with_reads = build_event(
        content_hash: "reads5",
        title: "Test",
        summary: "Test",
        nodes: [],
        edges: [],
        extraction: {
          read_set: [
            { node_id: acme_corp.id, tools: [ "get_node_edges" ] }
          ],
          edge_reads: [ works_at_edge.id ]
        }
      )

      handler.call(event_with_reads)
      handler.call(event_with_reads)

      expect(NodeExtractionRead.where(extraction_id: event_with_reads.data[:extraction_id]).count).to eq(1)
      expect(EdgeExtractionRead.where(extraction_id: event_with_reads.data[:extraction_id]).count).to eq(1)
    end
  end

  it "skips edges with unknown node slugs" do
    event_with_missing = build_event(
      content_hash: "ghi789",
      title: "Test",
      summary: "Test",
      nodes: [
        { name: "Acme Corp", kind: "company", description: "Ruby consultancy" }
      ],
      edges: [
        { source: "Unknown Person", target: "Acme Corp", relation: "works_at", context: "test" }
      ]
    )

    handler.call(event_with_missing)

    expect(Edge.count).to eq(0)
  end
end
