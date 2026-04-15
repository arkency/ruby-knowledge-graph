class NodeExtraction < ApplicationRecord
  self.primary_key = [:node_id, :extraction_id]

  belongs_to :node, counter_cache: :extractions_count
  belongs_to :extraction, counter_cache: :nodes_count

  scope :creates, -> { where(kind: "create") }
  scope :updates, -> { where(kind: "update") }
end
