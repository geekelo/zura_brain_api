class CreatePaymentMethods < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_methods do |t|
      t.references :session, null: false, foreign_key: true
      t.string :source # pos, online, cash, bank, other
      t.string :type # tip, massage, lunez, other
      t.decimal :amount
      t.string :status # refunded, ok, nonrefunded

      t.timestamps
    end
  end
end
