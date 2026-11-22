class CreateDisputes < ActiveRecord::Migration[7.2]
  def change
    create_table :disputes do |t|
      t.references :session, null: false, foreign_key: { on_delete: :cascade }
      t.text :description, null: false
      t.jsonb :thread, null: false, default: []
      t.boolean :resolved, null: false, default: false
      t.jsonb :resolution, null: false, default: { "text" => "", "image_urls" => [] }

      t.timestamps
    end

    create_table :dispute_therapists do |t|
      t.references :dispute, null: false, foreign_key: { on_delete: :cascade }
      t.references :therapist, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :dispute_therapists, [:dispute_id, :therapist_id], unique: true
  end
end
