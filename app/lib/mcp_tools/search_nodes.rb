class McpTools::SearchNodes < MCP::Tool
  extend McpTools::FromRubyLlmTool
  from_ruby_llm_tool Tools::SearchNodes

  class << self
    def call(query:, kind: nil, server_context: nil)
      result = Tools::SearchNodes.new(read_collector: NullReadCollector.new).execute(query: query, kind: kind)
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
