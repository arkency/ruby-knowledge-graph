require "erb"

module ExtractionPrompt
  MODEL = Rails.env.production? ? "claude-opus-4-6" : "claude-haiku-4-5"
  TEMPLATE = ERB.new(Rails.root.join("app/lib/prompts/extraction.md.erb").read, trim_mode: "-")

  AVAILABLE_MODELS = begin
    models = RubyLLM.models
      .by_provider("anthropic")
      .chat_models
      .group_by(&:family)
      .map { |_, ms| ms.max_by(&:created_at) }
      .sort_by(&:name)
      .map(&:id)
    models.unshift(models.delete(MODEL)) if models.include?(MODEL)
    models.freeze
  end

  def self.for(format:, kind:)
    ontology = Ontology
    format_context = load_format_context(format)
    kind_context = load_kind_context(kind)
    TEMPLATE.result(binding)
  end

  private

  def self.load_format_context(format)
    path = Rails.root.join("app/lib/prompts/formats/#{format}.md")
    path.exist? ? path.read.strip : nil
  end

  def self.load_kind_context(kind)
    path = Rails.root.join("app/lib/prompts/kinds/#{kind}.md")
    path.exist? ? path.read.strip : nil
  end
end
