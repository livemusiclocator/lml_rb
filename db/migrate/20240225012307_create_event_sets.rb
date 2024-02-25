class CreateEventSets < ActiveRecord::Migration[7.1]
  def change
    create_table :event_sets do |t|
      t.timestamp :start_time
      t.timestamp :finish_time

      t.timestamps
    end
  end
end
