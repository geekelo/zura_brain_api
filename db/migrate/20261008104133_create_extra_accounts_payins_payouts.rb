class CreateExtraAccountsPayinsPayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :extra_accounts do |t|
      t.references :session_therapist, null: true, foreign_key: true
      t.string :type, null: true # payin, payout 
      t.decimal :amount, null: true, precision: 10, scale: 2
      t.string :description, null: true
      
      t.timestamps
    end
  end
end
