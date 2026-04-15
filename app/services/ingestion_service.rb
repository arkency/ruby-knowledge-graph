class IngestionService
  ExtractionAlreadyInProgress = Class.new(StandardError)

  def initialize(event_store: Rails.configuration.event_store)
    @repository = AggregateRoot::Repository.new(event_store)
  end

  def request_extraction(content_hash:, ingestion_id:, model_id: nil)
    with_aggregate(content_hash) do |process|
      process.request_extraction(ingestion_id: ingestion_id, model_id: model_id || ExtractionPrompt::MODEL)
    end
  end

  def start_extraction(content_hash:, extraction_id:)
    with_aggregate(content_hash) do |process|
      process.start_extraction(extraction_id: extraction_id)
    end
  end

  def complete_extraction(content_hash:, extraction_id:, title:, summary:, nodes:, edges:, extraction:)
    with_aggregate(content_hash) do |process|
      process.complete_extraction(
        extraction_id: extraction_id,
        title: title, summary: summary, nodes: nodes, edges: edges, extraction: extraction
      )
    end
  end

  def fail_extraction(content_hash:, extraction_id:, error_class:, error_message:, extraction: {})
    with_aggregate(content_hash) do |process|
      process.fail_extraction(
        extraction_id: extraction_id,
        error_class: error_class, error_message: error_message, extraction: extraction
      )
    end
  end

  private

  def with_aggregate(content_hash, &block)
    @repository.with_aggregate(Ingestion.new, "Ingestion$#{content_hash}", &block)
  end

  class Ingestion
    include AggregateRoot

    def initialize
      @extraction_pending = false
      @extractions_completed = 0
      @current_extraction_number = 0
      @ingestion_id = nil
      @content_hash = nil
    end

    def request_extraction(ingestion_id:, model_id:)
      raise ExtractionAlreadyInProgress if @extraction_pending

      apply ExtractionRequested.new(
        data: {
          extraction_id: SecureRandom.uuid,
          ingestion_id: ingestion_id,
          model_id: model_id,
          extraction_number: @extractions_completed + 1
        }
      )
    end

    def start_extraction(extraction_id:)
      apply KnowledgeExtractionStarted.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: @ingestion_id,
          content_hash: @content_hash,
          extraction_number: @current_extraction_number
        }
      )
    end

    def complete_extraction(extraction_id:, title:, summary:, nodes:, edges:, extraction:)
      apply KnowledgeExtracted.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: @ingestion_id,
          content_hash: @content_hash,
          extraction_number: @current_extraction_number,
          title: title, summary: summary, nodes: nodes, edges: edges, extraction: extraction
        }
      )
    end

    def fail_extraction(extraction_id:, error_class:, error_message:, extraction: {})
      apply KnowledgeExtractionFailed.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: @ingestion_id,
          content_hash: @content_hash,
          extraction_number: @current_extraction_number,
          error_class: error_class, error_message: error_message, extraction: extraction
        }
      )
    end

    on TranscriptIngested do |event|
      @ingestion_id = event.data["ingestion_id"]
      @content_hash = event.data["content_hash"]
    end

    on ExtractionRequested do |event|
      @extraction_pending = true
      @ingestion_id = event.data["ingestion_id"]
      @current_extraction_number = event.data["extraction_number"]
    end

    on KnowledgeExtractionStarted do |_event|
    end

    on KnowledgeExtracted do |_event|
      @extraction_pending = false
      @extractions_completed += 1
    end

    on KnowledgeExtractionFailed do |_event|
      @extraction_pending = false
    end
  end

  private_constant :Ingestion
end
