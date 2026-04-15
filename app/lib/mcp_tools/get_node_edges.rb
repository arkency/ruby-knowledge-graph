class McpTools::GetNodeEdges < MCP::Tool
  extend McpTools::FromRubyLlmTool
  from_ruby_llm_tool Tools::GetNodeEdges

  class << self
    def call(slug:, server_context: nil)
      result = Tools::GetNodeEdges.new(read_collector: NullReadCollector.new).execute(slug: slug)
      MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
    end
  end
end
