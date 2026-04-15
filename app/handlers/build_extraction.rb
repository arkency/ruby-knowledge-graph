class BuildExtraction
  def call(event)
    data = event.data.with_indifferent_access

    case event
    when ExtractionRequested then queued(data)
    when KnowledgeExtractionStarted then started(data)
    when KnowledgeExtracted then completed(data)
    when KnowledgeExtractionFailed then failed(data)
    end
  end

  private

  def queued(data)
    with_extraction(data.fetch(:extraction_id)) do |extraction|
      extraction.ingestion_id = data.fetch(:ingestion_id)
      extraction.model_id = data[:model_id]
      extraction.status = "queued"
    end
  end

  def started(data)
    with_extraction(data.fetch(:extraction_id)) do |extraction|
      extraction.status = "started"
    end
  end

  def completed(data)
    with_extraction(data.fetch(:extraction_id)) do |extraction|
      extraction.status = "completed"
      extraction.title = data[:title]
      extraction.summary = data[:summary]
      apply_metrics(extraction, data[:extraction])
    end
  end

  def failed(data)
    with_extraction(data.fetch(:extraction_id)) do |extraction|
      extraction.status = "failed"
      extraction.error_class = data[:error_class]
      extraction.error_message = data[:error_message]
      apply_metrics(extraction, data[:extraction])
    end
  end

  def apply_metrics(extraction, extraction_data)
    return unless extraction_data

    extraction.model_id = extraction_data[:model_id] if extraction_data[:model_id]
    extraction.input_tokens = extraction_data[:input_tokens]
    extraction.output_tokens = extraction_data[:output_tokens]
    extraction.cached_tokens = extraction_data[:cached_tokens]
    extraction.cache_creation_tokens = extraction_data[:cache_creation_tokens]
    extraction.duration_ms = extraction_data[:duration_ms]
    extraction.roundtrips = extraction_data[:roundtrips]
    extraction.tool_calls = extraction_data[:tool_calls]
  end

  def with_extraction(id)
    extraction = Extraction.find_or_initialize_by(id: id)
    yield extraction
    extraction.save!
  end
end
