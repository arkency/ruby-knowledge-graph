require "rails_helper"

RSpec.describe Tools::GetNodeEdges do
  subject(:tool) { described_class.new(read_collector: ExtractionReadCollector.new) }

  let!(:acme_corp) { Node.create!(slug: "acme-corp", name: "Acme Corp", kind: "company", description: "Ruby consultancy") }
  let!(:res) { Node.create!(slug: "rails-event-store", name: "Rails Event Store", kind: "tool", description: "Event sourcing library") }
  let!(:bob) { Node.create!(slug: "bob-smith", name: "Bob Smith", kind: "person", description: "Developer") }

  before do
    Edge.create!(source_node: bob, target_node: acme_corp, relation: "works_at", context: "Bob works at Acme Corp")
    Edge.create!(source_node: acme_corp, target_node: res, relation: "uses", context: "Acme Corp uses RES")
  end

  it "returns edges for a node" do
    result = tool.execute(slug: "acme-corp")

    expect(result[:outgoing_edges]).to contain_exactly(
      a_hash_including(relation: "uses", target: a_hash_including(name: "Rails Event Store", slug: "rails-event-store", kind: "tool"))
    )
    expect(result[:incoming_edges]).to contain_exactly(
      a_hash_including(relation: "works_at", source: a_hash_including(name: "Bob Smith", slug: "bob-smith", kind: "person"))
    )
  end

  it "returns not found message for nonexistent slug" do
    result = tool.execute(slug: "nonexistent")

    expect(result).to eq("Node 'nonexistent' not found")
  end
end
