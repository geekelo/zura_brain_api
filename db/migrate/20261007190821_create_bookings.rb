class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.references :client, null: false, foreign_key: true
      t.datetime :booking_date
      t.decimal :amount
      t.string :cycle
      t.string :cycle_session
      t.string :status
      t.text :comments

      t.timestamps
    end
  end
end
