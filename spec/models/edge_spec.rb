require "rails_helper"

RSpec.describe Edge, type: :model do
  let(:source) { Node.create!(slug: "person-a", name: "Person A", kind: "person") }
  let(:target) { Node.create!(slug: "company-b", name: "Company B", kind: "company") }

  it "validates presence of relation" do
    edge = Edge.new(source_node: source, target_node: target)
    expect(edge).not_to be_valid
    expect(edge.errors[:relation]).to include("can't be blank")
  end

  it "validates uniqueness of source_node_id + target_node_id + relation" do
    Edge.create!(source_node: source, target_node: target, relation: "works_at")
    duplicate = Edge.new(source_node: source, target_node: target, relation: "works_at")
    expect(duplicate).not_to be_valid
  end

  it "allows different relations between same nodes" do
    Edge.create!(source_node: source, target_node: target, relation: "works_at")
    different = Edge.new(source_node: source, target_node: target, relation: "contributed_to")
    expect(different).to be_valid
  end
end
