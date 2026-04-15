module McpServerConfig
  def self.build_server
    MCP::Server.new(
      name: "planet-knowledge-graph",
      version: "1.0.0",
      instructions: "This server provides access to #{Rails.configuration.planet.organization_name}'s knowledge graph.",
      tools: [McpTools::GetNodeKinds, McpTools::SearchNodes, McpTools::GetNodeEdges, McpTools::ListNodesByKind]
    )
  end
end
