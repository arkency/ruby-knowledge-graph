class Edge < ApplicationRecord
  belongs_to :source_node, class_name: "Node", counter_cache: :outgoing_edges_count
  belongs_to :target_node, class_name: "Node", counter_cache: :incoming_edges_count

  has_many :edge_extractions, dependent: :destroy
  has_many :edge_extraction_reads, dependent: :destroy

  validates :relation, presence: true
  validates :source_node_id, uniqueness: { scope: [:target_node_id, :relation] }
end
