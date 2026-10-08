class CreateTechAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_accounts do |t|
      t.references :extra_account, null: false, foreign_key: true
      t.decimal :amount
      t.datetime :transaction_date
      t.boolean :settled

      t.timestamps
    end
  end
end
