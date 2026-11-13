class CreateClients < ActiveRecord::Migration[7.2]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :phone, index: { unique: true }
      t.text :other_phones, array: true, default: []
      t.string :sex
      t.integer :cycle
      t.string :cycle_length
      t.string :created_by
      t.boolean :adult

      t.timestamps
    end
  end
end
