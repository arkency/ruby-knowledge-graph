class ExtractionsController < ApplicationController
  def index
    @extractions = Extraction.includes(:ingestion).order(created_at: :desc)
    @extractions = @extractions.where.not(status: "failed") if params[:hide_failed]
  end

  def show
    @extraction = Extraction.includes(:ingestion,
      node_extractions: :node,
      edge_extractions: { edge: [ :source_node, :target_node ] },
      node_extraction_reads: :node,
      edge_extraction_reads: { edge: [ :source_node, :target_node ] }
    ).find(params[:id])
  end
end
