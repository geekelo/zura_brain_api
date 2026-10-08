class CreateSessionTherapists < ActiveRecord::Migration[7.2]
  def change
    create_table :session_therapists do |t|
      t.references :session, null: false, foreign_key: true
      t.references :therapist, null: false, foreign_key: true
      t.string :role
      t.decimal :tip_amount
      t.decimal :tip_balance
      t.decimal :points, default: 0
      t.text :feedback, null: true

      t.timestamps
    end
  end
end
