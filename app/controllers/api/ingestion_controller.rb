module Api
  class IngestionController < ApplicationController
    skip_forgery_protection
    skip_before_action :basic_auth

    before_action :authenticate!

    def create
      format = params[:format]
      kind = params[:kind]
      content = params[:content]
      external_id = params[:external_id]
      metadata = params[:metadata] || {}

      return render json: { error: "content is required" }, status: :unprocessable_entity if content.blank?
      return render json: { error: "format is required" }, status: :unprocessable_entity if format.blank?

      content_hash = Digest::SHA256.hexdigest(content)
      ingestion_id = SecureRandom.uuid

      event = TranscriptIngested.new(
        data: {
          ingestion_id: ingestion_id,
          format: format,
          kind: kind,
          content_hash: content_hash,
          content: content,
          external_id: external_id,
          metadata: metadata
        }
      )

      begin
        event_store.publish(event, stream_name: "Ingestion$#{content_hash}", expected_version: :none)
      rescue RubyEventStore::WrongExpectedEventVersion
        return render json: { status: "duplicate", content_hash: content_hash }, status: :ok
      end

      render json: { status: "accepted", ingestion_id: ingestion_id, content_hash: content_hash }, status: :accepted
    end

    private

    def authenticate!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")
      expected = ENV["WEBHOOK_TOKEN"]

      unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)
        render json: { error: "unauthorized" }, status: :unauthorized
      end
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
