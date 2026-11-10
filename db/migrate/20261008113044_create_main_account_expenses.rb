class CreateMainAccountExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :main_account_expenses do |t|
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
