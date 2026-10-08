class CreateExtraAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :extra_accounts do |t|
      t.references :session_therapist, null: false, foreign_key: true
      t.decimal :amount

      t.timestamps
    end
  end
end
