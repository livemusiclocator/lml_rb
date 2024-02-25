class AddEventStatusToEvents < ActiveRecord::Migration[7.1]
  def change
    add_reference :events, :event_status, foreign_key: true
  end
end
