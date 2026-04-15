require "rails_helper"

RSpec.describe BuildExtraction do
  subject(:handler) { described_class.new }

  let(:extraction_id) { SecureRandom.uuid }
  let(:ingestion_id) { SecureRandom.uuid }
  let!(:ingestion) do
    Ingestion.create!(id: ingestion_id, content_hash: "abc123")
  end

  describe "on ExtractionRequested" do
    let(:event) do
      ExtractionRequested.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: ingestion_id,
          content_hash: "abc123",
          content: "test",
          format: "transcript",
          kind: "team-meeting"
        }
      )
    end

    it "creates an Extraction row in queued state" do
      handler.call(event)

      extraction = Extraction.find(extraction_id)
      expect(extraction.ingestion_id).to eq(ingestion_id)
      expect(extraction.status).to eq("queued")
    end
  end

  describe "on KnowledgeExtractionStarted" do
    let!(:extraction) do
      Extraction.create!(id: extraction_id, ingestion_id: ingestion_id, status: "queued")
    end
    let(:event) do
      KnowledgeExtractionStarted.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: ingestion_id,
          content_hash: "abc123"
        }
      )
    end

    it "updates status to started" do
      handler.call(event)

      expect(extraction.reload.status).to eq("started")
    end
  end

  describe "on KnowledgeExtracted" do
    let!(:extraction) do
      Extraction.create!(id: extraction_id, ingestion_id: ingestion_id, status: "started")
    end
    let(:event) do
      KnowledgeExtracted.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: ingestion_id,
          content_hash: "abc123",
          title: "Weekly sync", summary: "A meeting about planning",
          nodes: [], edges: [],
          extraction: {
            model_id: "claude-sonnet-4-6",
            input_tokens: 1000,
            output_tokens: 500,
            cached_tokens: 200,
            cache_creation_tokens: 100,
            duration_ms: 3500,
            roundtrips: 2
          }
        }
      )
    end

    it "updates status to completed with title, summary and metrics" do
      handler.call(event)

      extraction.reload
      expect(extraction.status).to eq("completed")
      expect(extraction.title).to eq("Weekly sync")
      expect(extraction.summary).to eq("A meeting about planning")
      expect(extraction.model_id).to eq("claude-sonnet-4-6")
      expect(extraction.input_tokens).to eq(1000)
      expect(extraction.output_tokens).to eq(500)
      expect(extraction.cached_tokens).to eq(200)
      expect(extraction.cache_creation_tokens).to eq(100)
      expect(extraction.duration_ms).to eq(3500)
      expect(extraction.roundtrips).to eq(2)
    end
  end

  describe "on KnowledgeExtractionFailed" do
    let!(:extraction) do
      Extraction.create!(id: extraction_id, ingestion_id: ingestion_id, status: "started")
    end
    let(:event) do
      KnowledgeExtractionFailed.new(
        data: {
          extraction_id: extraction_id,
          ingestion_id: ingestion_id,
          content_hash: "abc123",
          error_class: "RuntimeError",
          error_message: "API timeout"
        }
      )
    end

    it "updates status to failed with error details" do
      handler.call(event)

      extraction.reload
      expect(extraction.status).to eq("failed")
      expect(extraction.error_class).to eq("RuntimeError")
      expect(extraction.error_message).to eq("API timeout")
    end
  end
end
