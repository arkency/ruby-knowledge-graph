class AddAttrsToEdges < ActiveRecord::Migration[8.1]
  def change
    add_column :edges, :attrs, :jsonb, default: {}, null: false
  end
end
