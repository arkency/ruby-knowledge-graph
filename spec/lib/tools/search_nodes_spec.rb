require "rails_helper"

RSpec.describe Tools::SearchNodes do
  subject(:tool) { described_class.new(read_collector: ExtractionReadCollector.new) }

  before do
    Node.create!(slug: "john-doe", name: "John Doe", kind: "person", description: "Developer")
    Node.create!(slug: "rails-event-store", name: "Rails Event Store", kind: "tool", description: "Event sourcing library")
    Node.create!(slug: "acme-corp", name: "Acme Corp", kind: "company", description: "Ruby consultancy")
  end

  it "finds nodes by name similarity" do
    result = tool.execute(query: "Doe")

    nodes = result[:nodes]
    expect(nodes.size).to eq(1)
    expect(nodes.first).to include(name: "John Doe", kind: "person", slug: "john-doe")
  end

  it "handles fuzzy matches (typos)" do
    result = tool.execute(query: "Jon Doe")

    expect(result[:nodes].first).to include(name: "John Doe")
  end

  it "filters by kind" do
    result = tool.execute(query: "Acme Corp", kind: "company")

    nodes = result[:nodes]
    expect(nodes.size).to eq(1)
    expect(nodes.first).to include(name: "Acme Corp")
  end

  it "returns message when no nodes found" do
    result = tool.execute(query: "nonexistent")

    expect(result).to eq("No nodes found for 'nonexistent'.")
  end

  it "finds nodes via alias" do
    node = Node.find_by(slug: "acme-corp")
    NodeAlias.create!(node: node, name: "Ark")

    result = tool.execute(query: "Ark")

    expect(result[:nodes].map { |r| r[:name] }).to include("Acme Corp")
  end

  it "finds Jane Smith via alias 'jsmith'" do
    jane = Node.create!(slug: "jane-smith", name: "Jane Smith", kind: "person", description: "Developer")
    NodeAlias.create!(node: jane, name: "jsmith")

    result = tool.execute(query: "jsmith")

    expect(result[:nodes].first).to include(name: "Jane Smith")
  end

  it "deduplicates when both name and alias match" do
    node = Node.find_by(slug: "john-doe")
    NodeAlias.create!(node: node, name: "John Doe")

    result = tool.execute(query: "John Doe")

    slugs = result[:nodes].map { |r| r[:slug] }
    expect(slugs.count("john-doe")).to eq(1)
  end

  it "limits results to 10" do
    12.times do |i|
      Node.create!(slug: "test-node-#{i}", name: "Test Node #{i}", kind: "concept", description: "Test")
    end

    result = tool.execute(query: "Test Node")

    expect(result[:nodes].size).to eq(10)
  end
end
