class Node < ApplicationRecord
  has_many :outgoing_edges, class_name: "Edge", foreign_key: :source_node_id, dependent: :destroy
  has_many :incoming_edges, class_name: "Edge", foreign_key: :target_node_id, dependent: :destroy
  has_many :aliases, class_name: "NodeAlias", dependent: :destroy
  has_many :node_extractions, dependent: :destroy
  has_one  :creating_node_extraction, -> { creates }, class_name: "NodeExtraction"
  has_one  :creating_extraction, through: :creating_node_extraction, source: :extraction
  has_one  :last_updating_node_extraction,
           -> { updates.joins(:extraction).order("extractions.created_at DESC") },
           class_name: "NodeExtraction"
  has_one  :last_updating_extraction, through: :last_updating_node_extraction, source: :extraction
  has_many :node_extraction_reads, dependent: :destroy
  has_neighbors :embedding
  attr_accessor :search_sources

  def updates_count
    extractions_count - (creating_extraction ? 1 : 0)
  end

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :kind, presence: true

  SIMILARITY_THRESHOLD = 0.3
  SEMANTIC_THRESHOLD = 0.45

  scope :by_kind, ->(kind) { where(kind: kind) }

  scope :search, ->(query, limit: 20) {
    node_sim = sanitize_sql_array([ "similarity(nodes.name, ?)", query ])
    alias_sim = sanitize_sql_array([ "similarity(node_aliases.name, ?)", query ])

    direct = select("nodes.*, #{node_sim} AS similarity")
             .where("#{node_sim} > ?", SIMILARITY_THRESHOLD)

    via_alias = joins(:aliases)
                .select("nodes.*, #{alias_sim} AS similarity")
                .where("#{alias_sim} > ?", SIMILARITY_THRESHOLD)

    combined = from("(#{direct.to_sql} UNION #{via_alias.to_sql}) AS nodes")
               .select("DISTINCT ON (nodes.id) nodes.*")
               .order(Arel.sql("nodes.id, nodes.similarity DESC"))

    from("(#{combined.to_sql}) AS nodes")
      .order(Arel.sql("similarity DESC"))
      .limit(limit)
  }

  RRF_K = 60

  def self.hybrid_search(query, limit: 10)
    trigram_results = search(query, limit: limit).to_a

    semantic_results = begin
      response = RubyLLM.embed(query, model: "qwen3-embedding:4b", provider: :ollama, assume_model_exists: true)
      nearest_neighbors(:embedding, response.vectors, distance: "cosine")
        .limit(limit)
        .select { |n| n.neighbor_distance < SEMANTIC_THRESHOLD }
    rescue => e
      Rails.logger.warn("[Node.hybrid_search] Ollama unavailable, falling back to trigram only: #{e.message}")
      []
    end

    scores = Hash.new(0.0)
    sources = Hash.new { |h, k| h[k] = [] }
    nodes_by_id = {}

    trigram_results.each_with_index do |node, rank|
      scores[node.id] += 1.0 / (RRF_K + rank + 1)
      sources[node.id] << :trigram
      nodes_by_id[node.id] = node
    end

    semantic_results.each_with_index do |node, rank|
      scores[node.id] += 1.0 / (RRF_K + rank + 1)
      sources[node.id] << :semantic
      nodes_by_id[node.id] ||= node
    end

    scores.sort_by { |_, score| -score }
      .first(limit)
      .map do |id, _|
        node = nodes_by_id[id]
        node.search_sources = sources[id]
        node
      end
  end
end
