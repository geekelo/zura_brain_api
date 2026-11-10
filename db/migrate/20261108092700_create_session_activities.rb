class CreateSessionActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :session_activities do |t|
      t.references :session, null: false, foreign_key: true
      t.references :therapist, null: false, foreign_key: true
      t.string :action, null: false
      t.datetime :performed_at, null: false

      t.timestamps
    end
  end
end
