module Tools
  module NodeSerialization
    private

    def node_summary(node)
      entry = {
        name: node.name,
        kind: node.kind,
        slug: node.slug,
        short_description: node.short_description,
        description: node.description,
        attrs: attrs_to_a(node.attrs)
      }
      entry[:aliases] = node.aliases.map(&:name) if node.aliases.any?
      entry
    end

    def attrs_to_a(hash)
      (hash || {}).map { |k, v| { key: k, value: v } }
    end
  end
end
