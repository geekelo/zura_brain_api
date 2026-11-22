class AddSessionHistoryToSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :session_history, :jsonb, null: false, default: {
      "pending" => true,
      "started" => false,
      "ended" => false,
      "payment_verified" => false,
      "completed" => false,
      "disputed" => false,
      "tipped" => 0
    }
  end
end
