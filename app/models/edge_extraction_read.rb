class EdgeExtractionRead < ApplicationRecord
  self.primary_key = [ :edge_id, :extraction_id ]

  belongs_to :edge, counter_cache: :reads_count
  belongs_to :extraction, counter_cache: :edge_reads_count
end
