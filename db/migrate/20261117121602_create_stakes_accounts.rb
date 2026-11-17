class CreateStakesAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :stakes_accounts do |t|
      t.references :session, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2
      t.boolean :settled, null: false, default: false

      t.timestamps
    end
  end
end
