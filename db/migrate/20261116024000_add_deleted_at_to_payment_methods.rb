class AddDeletedAtToPaymentMethods < ActiveRecord::Migration[7.2]
  def change
    add_column :payment_methods, :deleted_at, :datetime
  end
end
