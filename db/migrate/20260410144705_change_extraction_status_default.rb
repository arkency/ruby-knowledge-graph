class ChangeExtractionStatusDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :extractions, :status, from: "started", to: "queued"
  end
end
