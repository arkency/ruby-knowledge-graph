class Extraction < ApplicationRecord
  belongs_to :ingestion, optional: true

  has_many :node_extractions, dependent: :destroy
  has_many :edge_extractions, dependent: :destroy
  has_many :node_extraction_reads, dependent: :destroy
  has_many :edge_extraction_reads, dependent: :destroy
end
