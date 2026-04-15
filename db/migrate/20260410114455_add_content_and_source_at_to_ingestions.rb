class AddContentAndSourceAtToIngestions < ActiveRecord::Migration[8.1]
  def change
    add_column :ingestions, :content, :text
    add_column :ingestions, :source_at, :datetime
  end
end
