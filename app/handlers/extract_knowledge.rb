class ExtractKnowledge < ApplicationJob
  prepend RailsEventStore::AsyncHandler

  queue_as :default
  limits_concurrency to: 1, key: "extract_knowledge", duration: 1.hour

  def perform(event)
    data = event.data.with_indifferent_access
    extraction_id = data.fetch(:extraction_id)
    ingestion_id = data.fetch(:ingestion_id)
    model_id = data[:model_id]

    total_input_tokens = 0
    total_output_tokens = 0
    total_cached_tokens = 0
    total_cache_creation_tokens = 0
    total_roundtrips = 0
    total_tool_calls = 0
    started_at = nil
    max_roundtrips = 15

    ingestion = Ingestion.find(ingestion_id)
    content_hash = ingestion.content_hash
    content = clean_content(ingestion.content, ingestion.format)
    format = ingestion.format
    kind = ingestion.kind
    source_date = ingestion.source_at&.strftime("%Y-%m-%d")

    ingestion_service.start_extraction(content_hash: content_hash, extraction_id: extraction_id)

    prompt = ExtractionPrompt.for(format: format, kind: kind)
    schema = ExtractionResultSchema.for(format: format)

    system_prompt = RubyLLM::Providers::Anthropic::Content.new(
      prompt,
      cache: true
    )

    today = Date.current.iso8601
    header = [
      ("Source date: #{source_date}" if source_date),
      "Today's date: #{today}"
    ].compact.join("\n") + "\n\n"

    user_prompt = RubyLLM::Providers::Anthropic::Content.new(
      "#{header}--- CONTENT ---\n#{content}\n--- END OF CONTENT ---",
      cache: true
    )

    if Rails.env.development?
      log_path = Rails.root.join("log/extractions/#{content_hash}.jsonl")
      FileUtils.mkdir_p(log_path.dirname)
      log_file = File.open(log_path, "w")
    end

    read_collector = ExtractionReadCollector.new

    chat = RubyLLM
      .chat(model: model_id, provider: :anthropic, assume_model_exists: true)
      .with_params(max_tokens: 128_000, thinking: { type: "adaptive" })
      .with_tool(Tools::SearchNodes.new(read_collector: read_collector))
      .with_tool(Tools::GetNodeEdges.new(read_collector: read_collector))
      .with_tool(Tools::ListNodesByKind.new(read_collector: read_collector))
      .with_schema(schema)
      .on_end_message do |msg|
        log_file&.puts(msg_to_json(msg))
        if msg.role == :assistant
          total_roundtrips += 1
          total_tool_calls += msg.tool_calls&.size.to_i if msg.tool_call?
          total_input_tokens += msg.input_tokens.to_i
          total_output_tokens += msg.output_tokens.to_i
          total_cached_tokens += msg.cached_tokens.to_i
          total_cache_creation_tokens += msg.cache_creation_tokens.to_i
          chat.with_tools(replace: true) if total_roundtrips >= max_roundtrips
        end
      end

    chat.add_message(role: :system, content: system_prompt)

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = chat.ask(user_prompt)
    finished_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    result = response.content.with_indifferent_access

    ingestion_service.complete_extraction(
      content_hash: content_hash,
      extraction_id: extraction_id,
      title: result[:title],
      summary: result[:summary],
      nodes: result[:nodes],
      edges: result[:edges],
      extraction: {
        model_id: response.model_id || ExtractionPrompt::MODEL,
        input_tokens: total_input_tokens,
        output_tokens: total_output_tokens,
        cached_tokens: total_cached_tokens,
        cache_creation_tokens: total_cache_creation_tokens,
        duration_ms: ((finished_at - started_at) * 1000).round,
        roundtrips: total_roundtrips,
        tool_calls: total_tool_calls,
        read_set: read_collector.read_set,
        edge_reads: read_collector.edge_reads
      }
    )
  rescue => e
    raise unless content_hash

    finished_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    ingestion_service.fail_extraction(
      content_hash: content_hash,
      extraction_id: extraction_id,
      error_class: e.class.name,
      error_message: e.message,
      extraction: {
        model_id: model_id,
        input_tokens: total_input_tokens,
        output_tokens: total_output_tokens,
        cached_tokens: total_cached_tokens,
        cache_creation_tokens: total_cache_creation_tokens,
        duration_ms: started_at ? ((finished_at - started_at) * 1000).round : nil,
        roundtrips: total_roundtrips,
        tool_calls: total_tool_calls
      }
    )
  ensure
    log_file&.close
  end

  private

  def clean_content(content, format)
    format == "transcript" ? VttCleaner.clean(content) : content
  end

  def ingestion_service
    @ingestion_service ||= IngestionService.new
  end

  def msg_to_json(msg)
    data = { role: msg.role, tool_call_id: msg.tool_call_id }.compact
    if msg.role == :assistant
      data[:input_tokens] = msg.input_tokens
      data[:output_tokens] = msg.output_tokens
      data[:cached_tokens] = msg.cached_tokens
      data[:cache_creation_tokens] = msg.cache_creation_tokens
    end
    if msg.tool_call?
      data[:tool_calls] = msg.tool_calls.transform_values { |tc| { name: tc.name, arguments: tc.arguments } }
    else
      data[:content] = msg.content
    end
    data.to_json
  end
end
