require "rails_helper"

RSpec.describe NodeAlias, type: :model do
  let(:node) { Node.create!(slug: "test-node", name: "Test Node", kind: "person") }

  it "validates presence of name" do
    alias_record = NodeAlias.new(node: node, name: nil)
    expect(alias_record).not_to be_valid
    expect(alias_record.errors[:name]).to include("can't be blank")
  end

  it "allows duplicate names across nodes" do
    other_node = Node.create!(slug: "other-node", name: "Other Node", kind: "person")
    NodeAlias.create!(node: node, name: "Bob")
    duplicate = NodeAlias.new(node: other_node, name: "Bob")
    expect(duplicate).to be_valid
  end

  it "belongs to a node" do
    alias_record = NodeAlias.create!(node: node, name: "Alias")
    expect(alias_record.node).to eq(node)
  end
end
