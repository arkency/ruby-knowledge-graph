require "rails_helper"

RSpec.describe Tools::SearchNodes do
  subject(:tool) { described_class.new(read_collector: ExtractionReadCollector.new) }

  before do
    Node.create!(slug: "lukasz-reszke", name: "Łukasz Reszke", kind: "person", description: "Developer")
    Node.create!(slug: "rails-event-store", name: "Rails Event Store", kind: "tool", description: "Event sourcing library")
    Node.create!(slug: "acme-corp", name: "Acme Corp", kind: "company", description: "Ruby consultancy")
  end

  it "finds nodes by name similarity" do
    result = tool.execute(query: "Reszke")

    nodes = result[:nodes]
    expect(nodes.size).to eq(1)
    expect(nodes.first).to include(name: "Łukasz Reszke", kind: "person", slug: "lukasz-reszke")
  end

  it "includes hint to use get_node_edges" do
    result = tool.execute(query: "Reszke")

    expect(result[:hint]).to include("get_node_edges")
  end

  it "handles fuzzy matches (typos, missing diacritics)" do
    result = tool.execute(query: "Lukasz Reszke")

    expect(result[:nodes].first).to include(name: "Łukasz Reszke")
  end

  it "filters by kind" do
    result = tool.execute(query: "Acme Corp", kind: "company")

    nodes = result[:nodes]
    expect(nodes.size).to eq(1)
    expect(nodes.first).to include(name: "Acme Corp")
  end

  it "returns message when no nodes found" do
    result = tool.execute(query: "nonexistent")

    expect(result).to eq("No existing nodes found matching 'nonexistent'")
  end

  it "finds nodes via alias" do
    node = Node.find_by(slug: "acme-corp")
    NodeAlias.create!(node: node, name: "Ark")

    result = tool.execute(query: "Ark")

    expect(result[:nodes].map { |r| r[:name] }).to include("Acme Corp")
  end

  it "finds Piotr Romanczuk via alias 'porbas'" do
    piotr = Node.create!(slug: "piotr-romanczuk", name: "Piotr Romanczuk", kind: "person", description: "Developer")
    NodeAlias.create!(node: piotr, name: "porbas")

    result = tool.execute(query: "porbas")

    expect(result[:nodes].first).to include(name: "Piotr Romanczuk")
  end

  it "deduplicates when both name and alias match" do
    node = Node.find_by(slug: "lukasz-reszke")
    NodeAlias.create!(node: node, name: "Lukasz Reszke")

    result = tool.execute(query: "Lukasz Reszke")

    slugs = result[:nodes].map { |r| r[:slug] }
    expect(slugs.count("lukasz-reszke")).to eq(1)
  end

  it "limits results to 10" do
    12.times do |i|
      Node.create!(slug: "test-node-#{i}", name: "Test Node #{i}", kind: "concept", description: "Test")
    end

    result = tool.execute(query: "Test Node")

    expect(result[:nodes].size).to eq(10)
  end
end
