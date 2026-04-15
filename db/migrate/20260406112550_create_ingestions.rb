class CreateIngestions < ActiveRecord::Migration[8.1]
  def change
    create_table :ingestions, id: :uuid do |t|
      t.string :content_hash, null: false, index: { unique: true }
      t.string :format
      t.string :kind
      t.string :external_id
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
  end
end
