class AddMassageTypeToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :massage_type, :string
  end
end
