class CreateTherapists < ActiveRecord::Migration[7.2]
  def change
    create_table :therapists do |t|
      t.string :work_name unique: true
      t.boolean :active default: true
      t.string :avatar
      t.string :url
      t.string :code unique: true

      t.timestamps
    end
  end
end
