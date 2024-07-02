class RemoveDatetimeColumnsFromSets < ActiveRecord::Migration[7.1]
  def change
    remove_column :sets, :start_time
    remove_column :sets, :finish_time
  end
end
