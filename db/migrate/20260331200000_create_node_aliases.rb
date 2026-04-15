class CreateNodeAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :node_aliases, id: :uuid do |t|
      t.references :node, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    add_index :node_aliases, :name, unique: true
    add_index :node_aliases, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_node_aliases_on_name_trigram"
  end
end
