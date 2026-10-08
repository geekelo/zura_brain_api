class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :phone
      t.text :other_phones
      t.string :sex
      t.boolean :adult

      t.timestamps
    end
  end
end
