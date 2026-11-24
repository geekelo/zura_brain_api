class CreateTechPayinsPayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_payins_payouts do |t|
      t.references :extra_account, null: true, foreign_key: true
      t.references :session_therapist, null: true, foreign_key: { on_delete: :cascade }
      t.text :description, null: true
      t.decimal :amount, null: true, precision: 10, scale: 2
      t.string :type, null: true # payin, outflow, pending

      t.timestamps
    end
  end
end
