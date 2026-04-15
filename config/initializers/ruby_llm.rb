RubyLLM.configure do |config|
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.ollama_api_base = "#{ENV.fetch("OLLAMA_URL", "http://localhost:11434")}/v1"
end
