class AddEventToEventSets < ActiveRecord::Migration[7.1]
  def change
    add_reference :event_sets, :event, foreign_key: true
  end
end
