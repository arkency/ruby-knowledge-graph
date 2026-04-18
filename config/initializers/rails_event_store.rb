require "rails_event_store"
require "aggregate_root"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: JSON)
  )

  # Skip auto-extraction when running seeds — transcripts can be re-extracted
  # manually afterwards. Detected via the invoked rake task.
  seeding = defined?(Rake) && Rake.application.top_level_tasks.any? { |t|
    %w[db:seed db:setup db:reset].include?(t.to_s)
  }

  Rails.configuration.event_store.tap do |store|
    store.subscribe(BuildIngestion.new, to: [ TranscriptIngested, ExtractionRequested, KnowledgeExtractionStarted, KnowledgeExtracted, KnowledgeExtractionFailed ])
    store.subscribe(RequestExtraction.new, to: [ TranscriptIngested ]) unless seeding
    store.subscribe(BuildExtraction.new, to: [ ExtractionRequested, KnowledgeExtractionStarted, KnowledgeExtracted, KnowledgeExtractionFailed ])
    store.subscribe(ExtractKnowledge, to: [ ExtractionRequested ])
    store.subscribe(BuildKnowledgeGraph.new, to: [ KnowledgeExtracted ])
  end
end
