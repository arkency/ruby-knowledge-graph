class CreateEdges < ActiveRecord::Migration[8.1]
  def change
    create_table :edges, id: :uuid do |t|
      t.references :source_node, null: false, foreign_key: { to_table: :nodes }, type: :uuid
      t.references :target_node, null: false, foreign_key: { to_table: :nodes }, type: :uuid
      t.string :relation, null: false
      t.text   :context
      t.timestamps
    end

    add_index :edges, [ :source_node_id, :target_node_id, :relation ], unique: true, name: "idx_edges_unique_triple"
  end
end
