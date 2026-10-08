class CreateTechPayins < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_payins do |t|
      t.text :description
      t.decimal :amount

      t.timestamps
    end
  end
end
