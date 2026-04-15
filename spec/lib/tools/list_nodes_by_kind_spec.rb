require "rails_helper"

RSpec.describe Tools::ListNodesByKind do
  subject(:tool) { described_class.new(read_collector: ExtractionReadCollector.new) }

  before do
    Node.create!(slug: "lukasz-reszke", name: "Łukasz Reszke", kind: "person", description: "Developer")
    Node.create!(slug: "piotr-jurewicz", name: "Piotr Jurewicz", kind: "person", description: "Developer")
    Node.create!(slug: "rails-event-store", name: "Rails Event Store", kind: "tool", description: "Event sourcing library")
  end

  it "returns nodes of the given kind" do
    result = tool.execute(kind: "person")

    expect(result[:nodes].size).to eq(2)
    expect(result[:nodes].map { |n| n[:name] }).to contain_exactly("Łukasz Reszke", "Piotr Jurewicz")
  end

  it "includes slug for each node" do
    result = tool.execute(kind: "person")

    expect(result[:nodes]).to all(include(:slug))
  end

  it "includes aliases when present" do
    node = Node.find_by(slug: "lukasz-reszke")
    NodeAlias.create!(node: node, name: "Lukasz")

    result = tool.execute(kind: "person")

    lukasz = result[:nodes].find { |n| n[:slug] == "lukasz-reszke" }
    expect(lukasz[:aliases]).to eq(["Lukasz"])
  end

  it "omits aliases key when node has none" do
    result = tool.execute(kind: "person")

    result[:nodes].each do |n|
      expect(n).not_to have_key(:aliases)
    end
  end

  it "includes HATEOAS hint" do
    result = tool.execute(kind: "person")

    expect(result[:hint]).to include("get_node_edges")
  end

  it "returns message when no nodes of kind found" do
    result = tool.execute(kind: "event")

    expect(result).to eq("No nodes of kind 'event' found.")
  end

  it "limits results to 50" do
    55.times do |i|
      Node.create!(slug: "concept-#{i}", name: "Concept #{i}", kind: "concept", description: "Test")
    end

    result = tool.execute(kind: "concept")

    expect(result[:nodes].size).to eq(50)
  end

  it "returns nodes ordered by name" do
    result = tool.execute(kind: "person")

    names = result[:nodes].map { |n| n[:name] }
    expect(names).to eq(names.sort)
  end
end
