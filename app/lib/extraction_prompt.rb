require "erb"

module ExtractionPrompt
  MODEL = Rails.env.production? ? "claude-opus-4-7" : "claude-haiku-4-5"
  TEMPLATE = ERB.new(Rails.root.join("app/lib/prompts/extraction.md.erb").read, trim_mode: "-")

  EXTRA_MODELS = [ "claude-opus-4-7" ].freeze

  AVAILABLE_MODELS = begin
    models = RubyLLM.models
      .by_provider("anthropic")
      .chat_models
      .group_by(&:family)
      .map { |_, ms| ms.max_by(&:created_at) }
      .sort_by(&:name)
      .map(&:id)
    EXTRA_MODELS.each { |m| models.unshift(m) unless models.include?(m) }
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
