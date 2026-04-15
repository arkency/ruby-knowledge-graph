class AddToolCallsToExtractions < ActiveRecord::Migration[8.1]
  def change
    add_column :extractions, :tool_calls, :integer
  end
end
