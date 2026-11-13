class CreateTherapists < ActiveRecord::Migration[7.2]
  def change
    create_table :therapists do |t|
      t.string :work_name, index: { unique: true }
      t.boolean :active, default: true
      t.string :avatar
      t.string :url
      t.string :code, index: { unique: true }

      t.timestamps
    end
  end
end
