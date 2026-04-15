class AddShortDescriptionToNodes < ActiveRecord::Migration[8.0]
  def change
    add_column :nodes, :short_description, :string
  end
end
