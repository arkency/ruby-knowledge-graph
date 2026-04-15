class EdgeExtraction < ApplicationRecord
  self.primary_key = [ :edge_id, :extraction_id ]

  belongs_to :edge, counter_cache: :extractions_count
  belongs_to :extraction, counter_cache: :edges_count
end
