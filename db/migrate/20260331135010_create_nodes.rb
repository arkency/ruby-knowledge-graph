class CreateNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :nodes, id: :uuid do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :kind, null: false
      t.text   :description
      t.jsonb  :attrs, default: {}
      t.timestamps
    end

    add_index :nodes, :slug, unique: true
    add_index :nodes, :kind
  end
end
