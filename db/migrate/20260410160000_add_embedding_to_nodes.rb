class AddEmbeddingToNodes < ActiveRecord::Migration[8.1]
  def up
    enable_extension "vector"
    execute "ALTER TABLE nodes ADD COLUMN embedding vector(2560)"
  end

  def down
    remove_column :nodes, :embedding
    disable_extension "vector"
  end
end
