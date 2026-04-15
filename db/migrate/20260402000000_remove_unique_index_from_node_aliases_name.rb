class RemoveUniqueIndexFromNodeAliasesName < ActiveRecord::Migration[8.1]
  def change
    remove_index :node_aliases, :name, unique: true, name: "index_node_aliases_on_name"
    add_index :node_aliases, :name, name: "index_node_aliases_on_name"
  end
end
