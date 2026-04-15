module McpTools
  module FromRubyLlmTool
    def from_ruby_llm_tool(ruby_llm_tool)
      tool_name ruby_llm_tool.name.demodulize.underscore

      description ruby_llm_tool.description

      properties = {}
      required = []
      ruby_llm_tool.parameters.each do |name, param|
        properties[name] = { type: param.type, description: param.description }
        required << name.to_s if param.required
      end
      input_schema(properties: properties, required: required)
    end
  end
end
