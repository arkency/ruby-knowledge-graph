require "rails_helper"

RSpec.describe BuildIngestion do
  subject(:handler) { described_class.new }

  let(:ingestion_id) { SecureRandom.uuid }
  let(:extraction_id) { SecureRandom.uuid }

  def event(klass, extra = {})
    klass.new(data: { ingestion_id: ingestion_id, extraction_id: extraction_id, content_hash: "abc123" }.merge(extra))
  end

  describe "on TranscriptIngested" do
    let(:transcript_event) do
      event(TranscriptIngested, format: "transcript", kind: "team-meeting", external_id: "weekly-20260407", content: "x")
    end

    it "creates an Ingestion row from event data" do
      handler.call(transcript_event)

      ingestion = Ingestion.find(ingestion_id)
      expect(ingestion.content_hash).to eq("abc123")
      expect(ingestion.format).to eq("transcript")
      expect(ingestion.kind).to eq("team-meeting")
      expect(ingestion.external_id).to eq("weekly-20260407")
    end

    it "is idempotent on replay" do
      handler.call(transcript_event)
      handler.call(transcript_event)

      expect(Ingestion.where(id: ingestion_id).count).to eq(1)
    end
  end

  describe "status transitions" do
    before { Ingestion.create!(id: ingestion_id, content_hash: "abc123") }

    it "sets queued on ExtractionRequested" do
      handler.call(event(ExtractionRequested, content: "x", format: "transcript", kind: "weekly"))
      expect(Ingestion.find(ingestion_id).status).to eq("queued")
    end

    it "sets extracting on KnowledgeExtractionStarted" do
      handler.call(event(KnowledgeExtractionStarted))
      expect(Ingestion.find(ingestion_id).status).to eq("extracting")
    end

    it "sets extracted on KnowledgeExtracted" do
      handler.call(event(KnowledgeExtracted))
      expect(Ingestion.find(ingestion_id).status).to eq("extracted")
    end

    it "sets failed on KnowledgeExtractionFailed" do
      handler.call(event(KnowledgeExtractionFailed))
      expect(Ingestion.find(ingestion_id).status).to eq("failed")
    end

    it "sets requeued on ExtractionRequested with extraction_number > 1" do
      handler.call(event(ExtractionRequested, extraction_number: 2))
      expect(Ingestion.find(ingestion_id).status).to eq("requeued")
    end

    it "sets reextracted on KnowledgeExtracted with extraction_number > 1" do
      handler.call(event(KnowledgeExtracted, extraction_number: 2))
      expect(Ingestion.find(ingestion_id).status).to eq("reextracted")
    end

    it "sets re-extraction-failed on KnowledgeExtractionFailed with extraction_number > 1" do
      handler.call(event(KnowledgeExtractionFailed, extraction_number: 2))
      expect(Ingestion.find(ingestion_id).status).to eq("re-extraction-failed")
    end
  end

  it "is a no-op when ingestion_id is missing" do
    event_without_id = KnowledgeExtracted.new(data: { extraction_id: extraction_id })

    expect { handler.call(event_without_id) }.not_to raise_error
  end
end
