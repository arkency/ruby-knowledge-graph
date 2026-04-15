require "ruby_llm/schema"

module ExtractionResultSchema
  def self.for(format:)
    kind_names = Ontology.kind_names.join(", ")
    relation_names = Ontology.relation_names.join(", ")

    Class.new(RubyLLM::Schema) do
      name "extraction_result"
      description "Deep knowledge graph extraction."

      string :title, description: "Session title, max 100 chars"
      string :summary, description: "2-3 sentence summary"

      array :nodes, description: "Entities to create or update. Each name must be unique — no duplicate nodes." do
        object do
          string :name, description: "Entity name (unique)"
          string :kind, description: "Must be one of: #{kind_names}"
          string :short_description, description: "Stable synthesis of what this entity is (for search). General and identity-focused, not episode-specific. Max 15 words."
          string :description, description: "For new nodes: brief description based on the content. For existing nodes: synthesize prior description with new information. Rewriting for clarity is fine, but preserve prior facts."
          array :attrs, description: "Key-value attributes. Only include what is known from the content." do
            object do
              string :key, description: "Attribute name (snake_case)"
              string :value, description: "Attribute value"
            end
          end
        end
      end

      array :edges, description: "ALL relationships. Be thorough and precise." do
        object do
          string :source, description: "Source node name (exact match — existing or newly created)"
          string :target, description: "Target node name (exact match — existing or newly created)"
          string :relation, description: "Must be one of: #{relation_names}"
          string :context, description: "Briefly explain why this relationship exists, grounded in the content"
          array :attrs, description: "Key-value attributes for this edge (e.g. since, weight)" do
            object do
              string :key, description: "Attribute name (snake_case)"
              string :value, description: "Attribute value"
            end
          end
        end
      end
    end
  end
end
