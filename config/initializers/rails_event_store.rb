require "rails_event_store"
require "aggregate_root"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: JSON)
  )

  Rails.configuration.event_store.tap do |store|
    store.subscribe(BuildIngestion.new, to: [TranscriptIngested, ExtractionRequested, KnowledgeExtractionStarted, KnowledgeExtracted, KnowledgeExtractionFailed])
    store.subscribe(RequestExtraction.new, to: [TranscriptIngested])
    store.subscribe(BuildExtraction.new, to: [ExtractionRequested, KnowledgeExtractionStarted, KnowledgeExtracted, KnowledgeExtractionFailed])
    store.subscribe(ExtractKnowledge, to: [ExtractionRequested])
    store.subscribe(BuildKnowledgeGraph.new, to: [KnowledgeExtracted])
  end
end
