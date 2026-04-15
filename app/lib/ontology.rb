require "yaml"

module Ontology
  PATH = Rails.root.join("config/ontology.yml")

  class << self
    def instance
      @instance ||= load_from(PATH)
    end

    def kind_names
      instance.kind_names
    end

    def relation_names
      instance.relation_names
    end

    def node_kinds
      instance.node_kinds
    end

    def edge_relations
      instance.edge_relations
    end

    def reload!
      @instance = nil
    end

    private

    def load_from(path)
      data = YAML.load_file(path)
      Data.new(
        data.fetch("node_kinds", []),
        data.fetch("edge_relations", [])
      )
    end
  end

  class Data
    attr_reader :node_kinds, :edge_relations

    def initialize(node_kinds, edge_relations)
      @node_kinds = node_kinds
      @edge_relations = edge_relations
    end

    def kind_names
      node_kinds.map { |k| k.fetch("kind") }
    end

    def relation_names
      edge_relations.map { |r| r.fetch("relation") }
    end
  end
end
