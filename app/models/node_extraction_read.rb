class NodeExtractionRead < ApplicationRecord
  self.primary_key = [:node_id, :extraction_id]

  belongs_to :node, counter_cache: :reads_count
  belongs_to :extraction, counter_cache: :node_reads_count
end
