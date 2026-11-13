class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions do |t|
      t.references :client, null: false, foreign_key: true
      t.datetime :session_date, null: true
      t.decimal :amount, default: 0
      t.boolean :settled, default: false
      t.integer :cycle
      t.string :cycle_length
      t.boolean :lunez, default: false
      t.decimal :lunez_amount, default: 0
      t.string :hands, null: true
      t.jsonb :comments, null: false, default: []
      t.string :status, default: 'pending'
      t.references :session_creator, null: true, foreign_key: { to_table: :therapists}
      t.string :transaction_id, null: true
      t.string :session_code, index: { unique: true }
      t.string :session_type
      t.time :start_time, null: true
      t.time :end_time, null: true
      t.integer :duration, default: 0

      t.timestamps
    end
  end
end
