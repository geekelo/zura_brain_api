class AddAccountTypeToClientSupports < ActiveRecord::Migration[7.2]
  def change
    add_column :client_supports, :account_type, :string
    add_column :main_account_expenses, :type, :string, default: "payout"
  end
end
