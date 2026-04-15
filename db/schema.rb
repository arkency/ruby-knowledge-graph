# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_11_152224) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "vector"

  create_table "edge_extraction_reads", id: false, force: :cascade do |t|
    t.uuid "edge_id", null: false
    t.uuid "extraction_id", null: false
    t.index ["edge_id", "extraction_id"], name: "index_edge_extraction_reads_on_edge_id_and_extraction_id", unique: true
    t.index ["extraction_id"], name: "index_edge_extraction_reads_on_extraction_id"
  end

  create_table "edge_extractions", id: false, force: :cascade do |t|
    t.jsonb "diff", default: {}
    t.uuid "edge_id", null: false
    t.uuid "extraction_id", null: false
    t.string "kind", null: false
    t.index ["edge_id", "extraction_id"], name: "index_edge_extractions_on_edge_id_and_extraction_id", unique: true
    t.index ["edge_id"], name: "index_edge_extractions_on_edge_id"
    t.index ["extraction_id", "kind"], name: "index_edge_extractions_on_extraction_id_and_kind"
    t.index ["extraction_id"], name: "index_edge_extractions_on_extraction_id"
  end

  create_table "edges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "attrs", default: {}, null: false
    t.text "context"
    t.datetime "created_at", null: false
    t.integer "extractions_count", default: 0, null: false
    t.integer "reads_count", default: 0, null: false
    t.string "relation", null: false
    t.uuid "source_node_id", null: false
    t.uuid "target_node_id", null: false
    t.datetime "updated_at", null: false
    t.index ["source_node_id", "target_node_id", "relation"], name: "idx_edges_unique_triple", unique: true
    t.index ["source_node_id"], name: "index_edges_on_source_node_id"
    t.index ["target_node_id"], name: "index_edges_on_target_node_id"
  end

  create_table "event_store_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", null: false
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata"
    t.datetime "valid_at"
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "event_id", null: false
    t.integer "position"
    t.string "stream", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "extractions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.integer "edge_reads_count", default: 0, null: false
    t.integer "edges_count", default: 0, null: false
    t.string "error_class"
    t.text "error_message"
    t.uuid "ingestion_id"
    t.integer "input_tokens"
    t.string "model_id"
    t.integer "node_reads_count", default: 0, null: false
    t.integer "nodes_count", default: 0, null: false
    t.integer "output_tokens"
    t.integer "roundtrips"
    t.string "status", default: "queued", null: false
    t.text "summary"
    t.string "title"
    t.integer "tool_calls"
    t.datetime "updated_at", null: false
    t.index ["ingestion_id"], name: "index_extractions_on_ingestion_id"
  end

  create_table "ingestions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content"
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.string "external_id"
    t.string "format"
    t.string "kind"
    t.datetime "source_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["content_hash"], name: "index_ingestions_on_content_hash", unique: true
  end

  create_table "node_aliases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "node_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_node_aliases_on_name"
    t.index ["name"], name: "index_node_aliases_on_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["node_id"], name: "index_node_aliases_on_node_id"
  end

  create_table "node_extraction_reads", id: false, force: :cascade do |t|
    t.uuid "extraction_id", null: false
    t.uuid "node_id", null: false
    t.jsonb "tools", default: []
    t.index ["extraction_id"], name: "index_node_extraction_reads_on_extraction_id"
    t.index ["node_id", "extraction_id"], name: "index_node_extraction_reads_on_node_id_and_extraction_id", unique: true
  end

  create_table "node_extractions", id: false, force: :cascade do |t|
    t.jsonb "diff", default: {}
    t.uuid "extraction_id", null: false
    t.string "kind", null: false
    t.uuid "node_id", null: false
    t.index ["extraction_id", "kind"], name: "index_node_extractions_on_extraction_id_and_kind"
    t.index ["extraction_id"], name: "index_node_extractions_on_extraction_id"
    t.index ["node_id", "extraction_id"], name: "index_node_extractions_on_node_id_and_extraction_id", unique: true
    t.index ["node_id"], name: "index_node_extractions_on_node_id"
  end

  create_table "nodes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "attrs", default: {}
    t.datetime "created_at", null: false
    t.text "description"
    t.vector "embedding", limit: 2560
    t.integer "extractions_count", default: 0, null: false
    t.integer "incoming_edges_count", default: 0, null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.integer "outgoing_edges_count", default: 0, null: false
    t.integer "reads_count", default: 0, null: false
    t.string "short_description"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_nodes_on_kind"
    t.index ["name"], name: "index_nodes_on_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["slug"], name: "index_nodes_on_slug", unique: true
  end

  add_foreign_key "edge_extraction_reads", "edges"
  add_foreign_key "edge_extraction_reads", "extractions"
  add_foreign_key "edge_extractions", "edges"
  add_foreign_key "edge_extractions", "extractions"
  add_foreign_key "edges", "nodes", column: "source_node_id"
  add_foreign_key "edges", "nodes", column: "target_node_id"
  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
  add_foreign_key "extractions", "ingestions"
  add_foreign_key "node_aliases", "nodes"
  add_foreign_key "node_extraction_reads", "extractions"
  add_foreign_key "node_extraction_reads", "nodes"
  add_foreign_key "node_extractions", "extractions"
  add_foreign_key "node_extractions", "nodes"
end
