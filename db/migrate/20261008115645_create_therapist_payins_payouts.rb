class CreateTherapistPayinsPayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :therapist_payins_payouts do |t|
      t.references :therapist, null: false, foreign_key: true
      t.text :description, null: true
      t.decimal :amount, null: true, precision: 10, scale: 2
      t.string :type, null: true # payin, outflow, pending

      t.timestamps
    end
  end
end
