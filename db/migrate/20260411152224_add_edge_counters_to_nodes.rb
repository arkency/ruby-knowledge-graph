class AddEdgeCountersToNodes < ActiveRecord::Migration[8.1]
  def change
    add_column :nodes, :outgoing_edges_count, :integer, default: 0, null: false
    add_column :nodes, :incoming_edges_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE nodes SET outgoing_edges_count = (SELECT COUNT(*) FROM edges WHERE edges.source_node_id = nodes.id);
          UPDATE nodes SET incoming_edges_count = (SELECT COUNT(*) FROM edges WHERE edges.target_node_id = nodes.id);
        SQL
      end
    end
  end
end
