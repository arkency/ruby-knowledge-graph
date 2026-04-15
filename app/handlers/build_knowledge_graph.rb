class BuildKnowledgeGraph
  def call(event)
    data = event.data.deep_symbolize_keys
    extraction_data = data[:extraction] || {}

    ActiveRecord::Base.transaction do
      @extraction = Extraction.find(data.fetch(:extraction_id))
      @nodes_by_name = {}

      record_reads(extraction_data)

      (data[:nodes] || []).each { |n| upsert_node(n) }
      (data[:edges] || []).each { |e| upsert_edge(e) }
    end

    @nodes_by_name.each_value { |node| embed_node(node) }
  end

  private

  def upsert_node(data)
    node = resolve_node(data[:name])
    attrs = (data[:attrs] || [])
      .each_with_object({}) { |kv, h| h[kv[:key]] = kv[:value] }
      .compact_blank

    was_new = node.new_record?
    if was_new
      node.assign_attributes(name: data[:name], kind: data[:kind])
    end
    node.assign_attributes(short_description: data[:short_description], description: data[:description], attrs: node.attrs.merge(attrs))
    diff = node.changes.except("updated_at", "created_at")
    node.save!

    ne = NodeExtraction.find_or_create_by!(node: node, extraction: @extraction) do |new_ne|
      new_ne.kind = was_new ? "create" : "update"
    end
    ne.update!(diff: diff) if diff.present?

    @nodes_by_name[data[:name]] = node
  end

  def upsert_edge(data)
    source = find_node(data[:source])
    target = find_node(data[:target])
    return unless source && target

    attrs = (data[:attrs] || [])
      .each_with_object({}) { |kv, h| h[kv[:key]] = kv[:value] }
      .compact_blank

    edge = Edge.find_or_initialize_by(source_node: source, target_node: target, relation: data[:relation])
    was_new = edge.new_record?
    edge.assign_attributes(context: data[:context], attrs: edge.attrs.merge(attrs))
    diff = edge.changes.except("updated_at", "created_at")
    edge.save!

    ee = EdgeExtraction.find_or_create_by!(edge: edge, extraction: @extraction) do |new_ee|
      new_ee.kind = was_new ? "create" : "update"
    end
    ee.update!(diff: diff) if diff.present?
  end

  def find_node(name)
    @nodes_by_name[name] || resolve_node(name).then { |n| n.persisted? ? n : nil }
  end

  def record_reads(extraction_data)
    (extraction_data[:read_set] || []).each do |entry|
      node = Node.find_by(id: entry[:node_id])
      next unless node
      NodeExtractionRead
        .find_or_create_by!(node: node, extraction: @extraction)
        .update!(tools: entry[:tools] || [])
    end

    Edge.where(id: extraction_data[:edge_reads] || []).find_each do |edge|
      EdgeExtractionRead.find_or_create_by!(edge: edge, extraction: @extraction)
    end
  end

  def resolve_node(name)
    Node.find_by(slug: name.to_s.parameterize) ||
      NodeAlias.find_by(name: name)&.node ||
      Node.new(slug: name.to_s.parameterize)
  end

  def embed_node(node)
    text = node.short_description.present? ? "#{node.name} — #{node.short_description}" : "#{node.name} (#{node.kind})"
    response = RubyLLM.embed(text, model: "qwen3-embedding:4b", provider: :ollama, assume_model_exists: true)
    node.update_columns(embedding: "[#{response.vectors.join(",")}]")
  rescue => e
    Rails.logger.error("[BuildKnowledgeGraph] Failed to embed node #{node.slug}: #{e.message}")
  end
end
