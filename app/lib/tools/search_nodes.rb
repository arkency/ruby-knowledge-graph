class Tools::SearchNodes < RubyLLM::Tool
  include Tools::NodeSerialization
  description "Search the knowledge graph for nodes by name or keyword. Combines fuzzy name matching (trigram) with semantic vector search and ranks results using reciprocal rank fusion. Use this tool when looking for a specific entity or exploring what the graph knows about a topic. Returns up to 10 nodes sorted by relevance, each with name, kind, slug, short_description, description, attrs, aliases, similarity score, and search method (trigram/semantic)."

  param :query, desc: "Name, partial name, or descriptive phrase to search for"
  param :kind, desc: "When provided, filters results to only nodes of this kind. Omit to search across all kinds.", required: false

  def initialize(read_collector:)
    super()
    @read_collector = read_collector
  end

  def execute(query:, kind: nil)
    Rails.logger.info("[SearchNodes] query=#{query.inspect} kind=#{kind.inspect}")

    nodes = Node.hybrid_search(query, limit: 10)
    nodes = nodes.select { |n| n.kind == kind } if kind.present?

    @read_collector.searched(nodes.map(&:id), "search_nodes")

    result = if nodes.any?
      {
        nodes: nodes.map { |n|
          extra = {}
          extra[:similarity] = n.try(:similarity)&.round(2) if n.try(:similarity)
          extra[:via] = n.search_sources.join("+") if n.search_sources
          node_summary(n).merge(extra)
        }
      }
    else
      "No nodes found for '#{query}'."
    end

    Rails.logger.info("[SearchNodes] result=#{result.inspect}")
    result
  end
end
