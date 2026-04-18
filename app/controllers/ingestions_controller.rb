class IngestionsController < ApplicationController
  before_action :reject_if_extractions_locked, only: :extract

  def index
    @ingestions = Ingestion.order(created_at: :desc)
  end

  def show
    @ingestion = Ingestion.find(params[:id])
    @extractions = @ingestion.extractions.order(created_at: :desc)
  end

  def extract
    ingestion = Ingestion.find(params[:id])
    model_id = params[:model_id].presence

    IngestionService.new.request_extraction(
      content_hash: ingestion.content_hash,
      ingestion_id: ingestion.id,
      model_id: model_id
    )

    ingestion.reload
    flash_message = "Extraction queued (#{model_id || ExtractionPrompt::MODEL})."
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("flash", partial: "shared/flash", locals: { notice: flash_message }),
          turbo_stream.replace("ingestion-badge-#{ingestion.id}", partial: "shared/badge", locals: { dom_id: "ingestion-badge-#{ingestion.id}", status: ingestion.status }),
          turbo_stream.update("ingestion-actions-#{ingestion.id}", html: "")
        ]
      end
      format.html { redirect_to ingestion_path(ingestion), notice: flash_message }
    end
  rescue IngestionService::ExtractionAlreadyInProgress
    alert_message = "Extraction already in progress."
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash", locals: { alert: alert_message }) }
      format.html { redirect_to ingestion_path(ingestion), alert: alert_message }
    end
  end

  private

  def reject_if_extractions_locked
    return unless ENV["EXTRACTIONS_LOCKED"].present?

    alert_message = "Manual extractions are temporarily disabled."
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash", locals: { alert: alert_message }), status: :forbidden }
      format.html { redirect_to ingestion_path(params[:id]), alert: alert_message }
    end
  end
end
