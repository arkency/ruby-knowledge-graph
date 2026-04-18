module ApplicationHelper
  def extractions_locked?
    ENV["EXTRACTIONS_LOCKED"].present?
  end

  def extraction_cost(extraction)
    return nil unless extraction.model_id

    model = RubyLLM.models.find(extraction.model_id) rescue nil
    rates = model&.pricing&.text_tokens&.standard
    return nil unless rates

    # cache_write_per_million is read from RubyLLM model metadata (sourced from
    # models.dev) and reflects the 5-minute ephemeral cache rate. The spec
    # "uses 5-minute ephemeral cache (no ttl) on system and user prompts"
    # in extract_knowledge_spec.rb enforces that we don't silently switch to
    # the 1h cache, which would invalidate this rate.
    cache_write_rate = model.metadata.dig(:cost, :cache_write).to_f

    (extraction.input_tokens.to_i          * rates.input_per_million.to_f +
     extraction.output_tokens.to_i         * rates.output_per_million.to_f +
     extraction.cached_tokens.to_i         * rates.cached_input_per_million.to_f +
     extraction.cache_creation_tokens.to_i * cache_write_rate) / 1_000_000.0
  end

  def format_cost(cost)
    return "-" if cost.nil?
    if cost > 0 && cost < 0.01
      "$#{format('%.4f', cost)}"
    else
      "$#{format('%.2f', cost)}"
    end
  end
end
