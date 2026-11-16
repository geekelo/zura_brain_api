class AddOffCycleToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :off_cycle, :boolean, null: false, default: false
  end
end
