class CreateAdminNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :admin_notes do |t|
      t.references :client, null: false, foreign_key: true
      t.text :body
      t.string :status

      t.timestamps
    end
  end
end
