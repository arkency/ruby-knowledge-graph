require "rails_helper"

RSpec.describe "POST /api/ingest", type: :request do
  let(:token) { "test-token-123" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
  let(:valid_params) do
    {
      format: "transcript",
      content: "[10:00] Alice: Hi, let's start the meeting",
      external_id: "zoom-123",
      metadata: { meeting_id: "abc" }
    }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("WEBHOOK_TOKEN").and_return(token)
    allow(ExtractKnowledge).to receive(:perform_later)
  end

  it "accepts valid transcript and returns 202" do
    post "/api/ingest", params: valid_params.to_json, headers: headers

    expect(response).to have_http_status(:accepted)
    body = JSON.parse(response.body)
    expect(body["status"]).to eq("accepted")
      expect(body["ingestion_id"]).to be_present
    expect(body["content_hash"]).to be_present
  end

  it "publishes TranscriptIngested event" do
    post "/api/ingest", params: valid_params.to_json, headers: headers

    body = JSON.parse(response.body)
    content_hash = body["content_hash"]
    events = Rails.configuration.event_store.read.stream("Ingestion$#{content_hash}").to_a

    expect(events.size).to eq(1)
    expect(events.first).to be_a(TranscriptIngested)
    expect(events.first.data["format"]).to eq("transcript")
    expect(events.first.data["content"]).to eq(valid_params[:content])
  end

  it "returns duplicate for same content" do
    post "/api/ingest", params: valid_params.to_json, headers: headers
    expect(response).to have_http_status(:accepted)

    post "/api/ingest", params: valid_params.to_json, headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["status"]).to eq("duplicate")
  end

  it "returns 401 without valid token" do
    post "/api/ingest", params: valid_params.to_json, headers: headers.merge("Authorization" => "Bearer wrong")

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 422 without content" do
    post "/api/ingest", params: { format: "transcript" }.to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "returns 422 without format" do
    post "/api/ingest", params: { content: "test" }.to_json, headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
