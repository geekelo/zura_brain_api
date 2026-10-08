class CreateTherapists < ActiveRecord::Migration[7.2]
  def change
    create_table :therapists do |t|
      t.string :work_name
      t.boolean :active
      t.string :avatar
      t.string :url
      t.string :code

      t.timestamps
    end
  end
end
