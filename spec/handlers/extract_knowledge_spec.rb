require "rails_helper"

RSpec.describe ExtractKnowledge, type: :job do
  let(:extraction_id) { SecureRandom.uuid }
  let(:ingestion_id) { SecureRandom.uuid }
  let(:content_hash) { "abc123" }

  let(:event_store) { Rails.configuration.event_store }
  let(:stream) { "Ingestion$#{content_hash}" }

  let!(:ingestion) do
    Ingestion.create!(
      id: ingestion_id,
      content_hash: content_hash,
      content: "[10:00] Alice: Test meeting content",
      format: "transcript",
      kind: "team-meeting"
    )
  end

  before do
    event_store.publish(
      TranscriptIngested.new(data: {
        ingestion_id: ingestion_id,
        content_hash: content_hash,
        content: "x",
        format: "transcript",
        kind: "team-meeting"
      }),
      stream_name: stream
    )
    event_store.publish(
      ExtractionRequested.new(data: {
        extraction_id: extraction_id,
        ingestion_id: ingestion_id,
        model_id: ExtractionPrompt::MODEL,
        extraction_number: 1
      }),
      stream_name: stream
    )
  end

  def serialized_event(data_overrides = {})
    data = { extraction_id: extraction_id, ingestion_id: ingestion_id, model_id: ExtractionPrompt::MODEL }.merge(data_overrides)
    {
      "event_type" => "ExtractionRequested",
      "event_id" => SecureRandom.uuid,
      "data" => JSON.dump(data),
      "metadata" => JSON.dump({}),
      "timestamp" => Time.current.iso8601,
      "valid_at" => Time.current.iso8601
    }
  end

  # RubyLLM returns string keys from schema parsing
  let(:parsed_content) do
    {
      "title" => "Test meeting",
      "summary" => "A meeting about testing",
      "nodes" => [
        { "name" => "Acme Corp", "kind" => "company", "description" => "Ruby consultancy", "attrs" => {} }
      ],
      "edges" => []
    }
  end

  let(:llm_response) { double("RubyLLM::Message", content: parsed_content, model_id: ExtractionPrompt::MODEL) }

  let(:chat) { instance_double("RubyLLM::Chat") }

  before do
    allow(RubyLLM).to receive(:chat).and_return(chat)
    allow(chat).to receive(:add_message).and_return(chat)
    allow(chat).to receive(:with_tool).and_return(chat)
    allow(chat).to receive(:with_schema).and_return(chat)
    allow(chat).to receive(:with_thinking).and_return(chat)
    allow(chat).to receive(:on_end_message).and_return(chat)
    allow(chat).to receive(:ask).and_return(llm_response)
  end

  it "calls RubyLLM with tool and schema" do
    expect(RubyLLM).to receive(:chat).with(model: ExtractionPrompt::MODEL)
    expect(chat).to receive(:with_tool).with(an_instance_of(Tools::SearchNodes))
    expect(chat).to receive(:with_schema).with(an_instance_of(Class))
    expect(chat).to receive(:ask).with(an_instance_of(RubyLLM::Content::Raw))

    described_class.perform_now(serialized_event)
  end

  it "uses model_id from event data when provided" do
    expect(RubyLLM).to receive(:chat).with(model: "claude-opus-4-6")

    described_class.perform_now(serialized_event(model_id: "claude-opus-4-6"))
  end

  it "publishes KnowledgeExtractionStarted and KnowledgeExtracted events on success" do
    described_class.perform_now(serialized_event)

    all_events = Rails.configuration.event_store.read.to_a
    started_event = all_events.find { |e| e.is_a?(KnowledgeExtractionStarted) }
    knowledge_event = all_events.find { |e| e.is_a?(KnowledgeExtracted) }

    expect(started_event).to be_present
    expect(started_event.data["extraction_id"]).to eq(extraction_id)

    expect(knowledge_event).to be_present
    expect(knowledge_event.data["title"]).to eq("Test meeting")
    expect(knowledge_event.data["nodes"].size).to eq(1)
    expect(knowledge_event.data["extraction_id"]).to eq(extraction_id)
  end

  describe "read_set capture" do
    before do
      @captured_tools = []
      allow(chat).to receive(:with_tool) do |tool|
        @captured_tools << tool
        chat
      end
    end

    def simulate_reads(&block)
      allow(chat).to receive(:ask) do |_|
        collector = @captured_tools.first.instance_variable_get(:@read_collector)
        block.call(collector)
        llm_response
      end
    end

    def find_extracted_event
      Rails.configuration.event_store.read.to_a.find { |e| e.is_a?(KnowledgeExtracted) }
    end

    it "forwards node ids reported by search_nodes tool" do
      simulate_reads { |c| c.searched([ "node-1", "node-2" ], "search_nodes") }

      described_class.perform_now(serialized_event)

      read_set = find_extracted_event.data["extraction"]["read_set"]
      expect(read_set).to contain_exactly(
        { "node_id" => "node-1", "tools" => [ "search_nodes" ] },
        { "node_id" => "node-2", "tools" => [ "search_nodes" ] }
      )
    end

    it "forwards node ids reported by list_nodes_by_kind tool" do
      simulate_reads { |c| c.searched([ "node-1" ], "list_nodes_by_kind") }

      described_class.perform_now(serialized_event)

      read_set = find_extracted_event.data["extraction"]["read_set"]
      expect(read_set).to contain_exactly({ "node_id" => "node-1", "tools" => [ "list_nodes_by_kind" ] })
    end

    it "forwards anchor and edge ids reported by get_node_edges tool" do
      simulate_reads { |c| c.edges_inspected("node-acme-corp", [ "edge-1", "edge-2" ]) }

      described_class.perform_now(serialized_event)

      data = find_extracted_event.data["extraction"]
      expect(data["read_set"]).to contain_exactly({ "node_id" => "node-acme-corp", "tools" => [ "get_node_edges" ] })
      expect(data["edge_reads"]).to contain_exactly("edge-1", "edge-2")
    end

    it "records anchor read even when get_node_edges returns no edges" do
      simulate_reads { |c| c.edges_inspected("node-acme-corp", []) }

      described_class.perform_now(serialized_event)

      data = find_extracted_event.data["extraction"]
      expect(data["read_set"]).to contain_exactly({ "node_id" => "node-acme-corp", "tools" => [ "get_node_edges" ] })
      expect(data["edge_reads"]).to eq([])
    end

    it "merges tools when the same node is read by multiple tools" do
      simulate_reads do |c|
        c.searched([ "node-acme-corp" ], "search_nodes")
        c.edges_inspected("node-acme-corp", [])
      end

      described_class.perform_now(serialized_event)

      read_set = find_extracted_event.data["extraction"]["read_set"]
      expect(read_set.size).to eq(1)
      expect(read_set.first["node_id"]).to eq("node-acme-corp")
      expect(read_set.first["tools"]).to match_array([ "search_nodes", "get_node_edges" ])
    end

    it "produces an empty read_set when tools report nothing" do
      simulate_reads { |_c| } # no-op

      described_class.perform_now(serialized_event)

      expect(find_extracted_event.data["extraction"]["read_set"]).to eq([])
    end
  end

  describe "prompt cache configuration" do
    it "uses 5-minute ephemeral cache (no ttl) on system and user prompts" do
      captured_system = nil
      captured_user = nil

      allow(chat).to receive(:add_message) do |args|
        captured_system = args[:content] if args[:role] == :system
        chat
      end
      allow(chat).to receive(:ask) do |content|
        captured_user = content
        llm_response
      end

      described_class.perform_now(serialized_event)

      [ captured_system, captured_user ].each do |raw|
        expect(raw).to be_a(RubyLLM::Content::Raw)
        block = raw.value.first
        expect(block[:cache_control]).to eq({ type: "ephemeral" })
      end
    end
  end

  it "publishes KnowledgeExtractionFailed on error and does not re-raise" do
    allow(chat).to receive(:ask).and_raise(RuntimeError, "API error")

    expect { described_class.perform_now(serialized_event) }.not_to raise_error

    all_events = Rails.configuration.event_store.read.to_a
    started_event = all_events.find { |e| e.is_a?(KnowledgeExtractionStarted) }
    failed_event = all_events.find { |e| e.is_a?(KnowledgeExtractionFailed) }

    expect(started_event).to be_present
    expect(failed_event).to be_present
    expect(failed_event.data["extraction_id"]).to eq(extraction_id)
    expect(failed_event.data["error_class"]).to eq("RuntimeError")
    expect(failed_event.data["error_message"]).to eq("API error")

    extraction = failed_event.data["extraction"]
    expect(extraction["model_id"]).to eq(ExtractionPrompt::MODEL)
    expect(extraction["duration_ms"]).to be_a(Integer)
    expect(extraction["roundtrips"]).to eq(0)
  end
end
