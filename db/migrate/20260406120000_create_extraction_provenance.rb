class CreateExtractionProvenance < ActiveRecord::Migration[8.1]
  def change
    create_table :extractions, id: :uuid do |t|
      t.string :content_hash, null: false, index: true
      t.references :ingestion, null: true, foreign_key: true, type: :uuid
      t.string :title
      t.text :summary
      t.string :model_id
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :cached_tokens
      t.integer :cache_creation_tokens
      t.integer :duration_ms
      t.integer :nodes_count, default: 0, null: false
      t.integer :edges_count, default: 0, null: false
      t.integer :node_reads_count, default: 0, null: false
      t.integer :edge_reads_count, default: 0, null: false
      t.integer :roundtrips
      t.string :status, null: false, default: "started"
      t.string :error_class
      t.text :error_message
      t.timestamps
    end

    # Nodes written by extraction
    create_table :node_extractions, id: false do |t|
      t.references :node, null: false, foreign_key: true, type: :uuid
      t.references :extraction, null: false, foreign_key: true, type: :uuid
      t.string :kind, null: false
      t.jsonb :diff, default: {}
      t.index [ :node_id, :extraction_id ], unique: true
      t.index [ :extraction_id, :kind ]
    end

    # Edges written by extraction
    create_table :edge_extractions, id: false do |t|
      t.references :edge, null: false, foreign_key: true, type: :uuid
      t.references :extraction, null: false, foreign_key: true, type: :uuid
      t.string :kind, null: false
      t.jsonb :diff, default: {}
      t.index [ :edge_id, :extraction_id ], unique: true
      t.index [ :extraction_id, :kind ]
    end

    # Nodes read (via tools) during extraction
    create_table :node_extraction_reads, id: false do |t|
      t.uuid :node_id, null: false
      t.uuid :extraction_id, null: false
      t.jsonb :tools, default: []
      t.index [ :node_id, :extraction_id ], unique: true
      t.index :extraction_id
    end
    add_foreign_key :node_extraction_reads, :nodes
    add_foreign_key :node_extraction_reads, :extractions

    # Edges read (via get_node_edges) during extraction
    create_table :edge_extraction_reads, id: false do |t|
      t.uuid :edge_id, null: false
      t.uuid :extraction_id, null: false
      t.index [ :edge_id, :extraction_id ], unique: true
      t.index :extraction_id
    end
    add_foreign_key :edge_extraction_reads, :edges
    add_foreign_key :edge_extraction_reads, :extractions

    # Counter caches
    add_column :nodes, :extractions_count, :integer, default: 0, null: false
    add_column :nodes, :reads_count, :integer, default: 0, null: false
    add_column :edges, :extractions_count, :integer, default: 0, null: false
    add_column :edges, :reads_count, :integer, default: 0, null: false
  end
end
