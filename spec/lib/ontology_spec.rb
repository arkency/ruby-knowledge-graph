require "rails_helper"

RSpec.describe Ontology do
  before { Ontology.reload! }

  it "includes all node kinds" do
    expect(Ontology.kind_names).to include("person", "talk", "event", "company", "tool", "concept", "project")
  end

  it "includes all edge relations" do
    expect(Ontology.relation_names).to include("authored", "presented_at", "attended", "about", "works_at", "works_on", "uses", "has_skill", "related_to")
  end

  it "exposes node_kinds as raw hashes" do
    kind = Ontology.node_kinds.first
    expect(kind).to include("kind", "description")
  end

  it "exposes edge_relations as raw hashes" do
    rel = Ontology.edge_relations.first
    expect(rel).to include("relation", "signature")
  end
end
