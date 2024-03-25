class AddDurationToSets < ActiveRecord::Migration[7.1]
  def change
    add_column :sets, :duration, :integer
  end
end
