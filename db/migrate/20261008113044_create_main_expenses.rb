class CreateMainExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :main_expenses do |t|
      t.integer :month
      t.integer :year
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
