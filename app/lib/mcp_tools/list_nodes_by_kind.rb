class McpTools::ListNodesByKind < MCP::Tool
  extend McpTools::FromRubyLlmTool
  from_ruby_llm_tool Tools::ListNodesByKind

  class << self
    def call(kind:, server_context: nil)
      result = Tools::ListNodesByKind.new(read_collector: NullReadCollector.new).execute(kind: kind)
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
