class CreateSanctions < ActiveRecord::Migration[7.2]
  def change
    create_table :sanctions do |t|
      t.text :description
      t.references :therapist, null: true, foreign_key: { on_delete: :nullify }
      t.string :non_therapist
      t.decimal :amount, precision: 10, scale: 2
      t.string :type

      t.timestamps
    end
  end
end
