require "rails_helper"

RSpec.describe Node, type: :model do
  it "validates presence of slug, name, kind" do
    node = Node.new
    expect(node).not_to be_valid
    expect(node.errors[:slug]).to include("can't be blank")
    expect(node.errors[:name]).to include("can't be blank")
    expect(node.errors[:kind]).to include("can't be blank")
  end

  it "validates uniqueness of slug" do
    Node.create!(slug: "acme-corp", name: "Acme Corp", kind: "company")
    duplicate = Node.new(slug: "acme-corp", name: "Acme Corp 2", kind: "company")
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:slug]).to include("has already been taken")
  end

  it "has outgoing and incoming edges" do
    source = Node.create!(slug: "person-a", name: "Person A", kind: "person")
    target = Node.create!(slug: "company-b", name: "Company B", kind: "company")
    edge = Edge.create!(source_node: source, target_node: target, relation: "works_at")

    expect(source.outgoing_edges).to include(edge)
    expect(target.incoming_edges).to include(edge)
  end

  it "scopes by kind" do
    Node.create!(slug: "person-1", name: "Person 1", kind: "person")
    Node.create!(slug: "company-1", name: "Company 1", kind: "company")

    expect(Node.by_kind("person").count).to eq(1)
  end
end
