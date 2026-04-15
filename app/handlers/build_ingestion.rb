class BuildIngestion
  def call(event)
    data = event.data.with_indifferent_access

    case event
    when TranscriptIngested then ingested(event)
    when ExtractionRequested then queued(data)
    when KnowledgeExtractionStarted then extracting(data)
    when KnowledgeExtracted then completed(data)
    when KnowledgeExtractionFailed then failed(data)
    end
  end

  private

  def ingested(event)
    data = event.data.with_indifferent_access

    with_ingestion(data.fetch(:ingestion_id)) do |ingestion|
      ingestion.content_hash = data.fetch(:content_hash)
      ingestion.format = data[:format]
      ingestion.kind = data[:kind]
      ingestion.external_id = data[:external_id]
      ingestion.content = data[:content]
      ingestion.source_at = event.metadata[:valid_at]
    end
  end

  def queued(data)
    with_ingestion(data.fetch(:ingestion_id)) do |ingestion|
      ingestion.status = data[:extraction_number].to_i > 1 ? "requeued" : "queued"
    end
  end

  def extracting(data)
    with_ingestion(data[:ingestion_id]) do |ingestion|
      ingestion.status = "extracting"
    end
  end

  def completed(data)
    with_ingestion(data[:ingestion_id]) do |ingestion|
      ingestion.status = data[:extraction_number].to_i > 1 ? "reextracted" : "extracted"
    end
  end

  def failed(data)
    with_ingestion(data[:ingestion_id]) do |ingestion|
      ingestion.status = data[:extraction_number].to_i > 1 ? "re-extraction-failed" : "failed"
    end
  end

  def with_ingestion(id)
    return unless id

    ingestion = Ingestion.find_or_initialize_by(id: id)
    yield ingestion
    ingestion.save!
  end
end
