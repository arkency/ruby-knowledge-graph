class RequestExtraction
  def call(event)
    data = event.data.with_indifferent_access

    IngestionService.new.request_extraction(
      content_hash: data.fetch(:content_hash),
      ingestion_id: data.fetch(:ingestion_id)
    )
  end
end
