require "rails_helper"

RSpec.describe IngestionService do
  subject(:service) { described_class.new(event_store: event_store) }

  let(:event_store) { Rails.configuration.event_store }
  let(:content_hash) { "abc123" }
  let(:ingestion_id) { SecureRandom.uuid }
  let(:stream) { "Ingestion$#{content_hash}" }

  before do
    event_store.publish(
      TranscriptIngested.new(data: {
        ingestion_id: ingestion_id,
        content_hash: content_hash,
        content: "test content",
        format: "transcript",
        kind: "team-meeting"
      }),
      stream_name: stream
    )
  end

  describe "#request_extraction" do
    it "publishes ExtractionRequested with ingestion_id and extraction_id" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      event = event_store.read.stream(stream).of_type([ ExtractionRequested ]).first
      expect(event.data["ingestion_id"]).to eq(ingestion_id)
      expect(event.data["extraction_id"]).to be_present
    end

    it "passes model_id when provided" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id, model_id: "claude-opus-4-6")

      event = event_store.read.stream(stream).of_type([ ExtractionRequested ]).first
      expect(event.data["model_id"]).to eq("claude-opus-4-6")
    end

    it "sets extraction_number to 1 for first extraction" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      event = event_store.read.stream(stream).of_type([ ExtractionRequested ]).first
      expect(event.data["extraction_number"]).to eq(1)
    end

    it "increments extraction_number after completed extraction" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      event_store.publish(
        KnowledgeExtracted.new(data: {
          extraction_id: SecureRandom.uuid,
          ingestion_id: ingestion_id,
          content_hash: content_hash,
          title: "t", summary: "s", nodes: [], edges: [],
          extraction: {}
        }),
        stream_name: stream
      )

      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      events = event_store.read.stream(stream).of_type([ ExtractionRequested ]).to_a
      expect(events.last.data["extraction_number"]).to eq(2)
    end

    it "does not increment extraction_number after failed extraction" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      event_store.publish(
        KnowledgeExtractionFailed.new(data: {
          extraction_id: SecureRandom.uuid,
          ingestion_id: ingestion_id,
          content_hash: content_hash,
          error_class: "RuntimeError",
          error_message: "boom"
        }),
        stream_name: stream
      )

      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      events = event_store.read.stream(stream).of_type([ ExtractionRequested ]).to_a
      expect(events.last.data["extraction_number"]).to eq(1)
    end

    it "raises ExtractionAlreadyInProgress when extraction is pending" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      expect {
        service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)
      }.to raise_error(IngestionService::ExtractionAlreadyInProgress)
    end

    it "allows new extraction after previous one completed" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      event_store.publish(
        KnowledgeExtracted.new(data: {
          extraction_id: SecureRandom.uuid,
          ingestion_id: ingestion_id,
          content_hash: content_hash,
          title: "t", summary: "s", nodes: [], edges: [],
          extraction: {}
        }),
        stream_name: stream
      )

      expect {
        service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)
      }.not_to raise_error
    end

    it "allows new extraction after previous one failed" do
      service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)

      event_store.publish(
        KnowledgeExtractionFailed.new(data: {
          extraction_id: SecureRandom.uuid,
          ingestion_id: ingestion_id,
          content_hash: content_hash,
          error_class: "RuntimeError",
          error_message: "boom"
        }),
        stream_name: stream
      )

      expect {
        service.request_extraction(content_hash: content_hash, ingestion_id: ingestion_id)
      }.not_to raise_error
    end
  end
end
