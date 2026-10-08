class CreateSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :sessions do |t|
      t.references :client, null: false, foreign_key: true
      t.datetime :session_date
      t.decimal :amount, default: 0
      t.boolean :settled, default: false
      t.string :cycle
      t.string :cycle_session
      t.boolean :lunez, default: false
      t.decimal :lunez_amount, default: 0
      t.string :hands
      t.text :comments, null: true
      t.string :status, default: 'pending'
      t.boolean :car_washed, default: false
      t.string :proof_of_payment, null: true
      t.references :session_creator, null: true, foreign_key: { to_table: :therapists}
      t.string :session_code
      t.string :session_type

      t.timestamps
    end
  end
end
