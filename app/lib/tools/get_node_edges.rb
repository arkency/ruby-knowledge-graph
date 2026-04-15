class Tools::GetNodeEdges < RubyLLM::Tool
  include Tools::NodeSerialization
  description "Get all relationships (edges) of a node. Each edge represents a directed relationship between two nodes, with a relation type and optional context describing the connection. Use this tool to understand how a node connects to other entities in the graph, or to disambiguate between similar search results. Returns outgoing_edges and incoming_edges arrays, each edge with relation, context, attrs, and the connected node (name, kind, slug, short_description, description, attrs, aliases)."

  param :slug, desc: "Unique node identifier. Use slugs returned by search_nodes or list_nodes_by_kind."

  def initialize(read_collector:)
    super()
    @read_collector = read_collector
  end

  def execute(slug:)
    Rails.logger.info("[GetNodeEdges] slug=#{slug.inspect}")

    node = Node.find_by(slug: slug)
    unless node
      Rails.logger.info("[GetNodeEdges] result=not found")
      return "Node '#{slug}' not found"
    end

    outgoing = node.outgoing_edges.includes(target_node: :aliases).to_a
    incoming = node.incoming_edges.includes(source_node: :aliases).to_a

    @read_collector.edges_inspected(node.id, (outgoing + incoming).map(&:id))

    result = {
      outgoing_edges: outgoing.map { |e| edge_summary(e).merge(target: node_summary(e.target_node)) },
      incoming_edges: incoming.map { |e| edge_summary(e).merge(source: node_summary(e.source_node)) }
    }

    Rails.logger.info("[GetNodeEdges] result=#{node.name} (#{result[:outgoing_edges].size} out, #{result[:incoming_edges].size} in)")
    result
  end

  private

  def edge_summary(edge)
    { relation: edge.relation, context: edge.context, attrs: attrs_to_a(edge.attrs) }
  end
end
