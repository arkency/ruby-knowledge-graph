class EnablePgTrgmAndAddTrigramIndexToNodes < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"
    add_index :nodes, :name, using: :gin, opclass: :gin_trgm_ops, name: "index_nodes_on_name_trigram"
  end
end
