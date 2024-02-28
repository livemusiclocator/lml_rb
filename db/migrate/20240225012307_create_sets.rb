class CreateSets < ActiveRecord::Migration[7.1]
  def change
    create_table :sets, id: :uuid do |t|
      t.timestamp :start_time
      t.timestamp :finish_time

      t.timestamps
    end
  end
end
