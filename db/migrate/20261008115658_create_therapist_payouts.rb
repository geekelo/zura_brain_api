class CreateTherapistPayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :therapist_payouts do |t|
      t.references :therapist, null: false, foreign_key: true
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
