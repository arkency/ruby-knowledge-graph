class McpTools::GetNodeKinds < MCP::Tool
  tool_name "get_node_kinds"
  description "List all node kinds defined in the knowledge graph ontology. Each kind has a name and description. Use this tool first to discover valid kind values before calling list_nodes_by_kind or filtering search_nodes."

  input_schema(properties: {})

  class << self
    def call(server_context: nil)
      result = { node_kinds: Ontology.node_kinds }
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
