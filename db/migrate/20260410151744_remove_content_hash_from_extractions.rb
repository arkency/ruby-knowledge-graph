class RemoveContentHashFromExtractions < ActiveRecord::Migration[8.1]
  def change
    remove_index :extractions, :content_hash
    remove_column :extractions, :content_hash, :string
  end
end
