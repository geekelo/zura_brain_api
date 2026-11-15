class AddPaymentUrlToPaymentMethods < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_methods, :payment_url, :jsonb, null: false, default: []
    add_column :payment_methods, :receipt_uploaded_at, :datetime
  end
end
