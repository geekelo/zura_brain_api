class CreateTechPayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_payouts do |t|
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
