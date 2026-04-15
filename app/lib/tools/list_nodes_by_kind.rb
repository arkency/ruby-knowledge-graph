class Tools::ListNodesByKind < RubyLLM::Tool
  include Tools::NodeSerialization
  description "List all nodes of a given kind in the knowledge graph. Returns every node of the specified kind, sorted alphabetically by name. Use this tool to get a complete overview of known entities of a particular type. May return a large number of results. Returns nodes array, each with name, kind, slug, short_description, description, attrs, and aliases."

  param :kind, desc: "The node kind to list. Must match an existing kind in the graph exactly."

  def initialize(read_collector:)
    super()
    @read_collector = read_collector
  end

  def execute(kind:)
    Rails.logger.info("[ListNodesByKind] kind=#{kind.inspect}")

    nodes = Node.where(kind: kind).includes(:aliases).order(:name)

    @read_collector.searched(nodes.map(&:id), "list_nodes_by_kind")

    result = if nodes.any?
      { nodes: nodes.map { |n| node_summary(n) } }
    else
      "No nodes of kind '#{kind}' found."
    end

    Rails.logger.info("[ListNodesByKind] result=#{result.inspect}")
    result
  end
end
