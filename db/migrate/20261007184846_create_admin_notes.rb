class CreateAdminNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :admin_notes do |t|
      t.references :client, null: true, foreign_key: true
      t.references :session, null: true, foreign_key: true
      t.references :therapist, null: true, foreign_key: { to_table: :therapists}
      t.references :creator, null: true, foreign_key: { to_table: :therapists}
      t.text :body
      t.string :status, default: "unresolved"

      t.timestamps
    end
  end
end
