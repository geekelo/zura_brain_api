class AddClientPreferencesToClients < ActiveRecord::Migration[7.2]
  def change
    add_column :clients, :client_preferences, :text
  end
end
