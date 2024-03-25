class AddStartOffsetToSets < ActiveRecord::Migration[7.1]
  def change
    add_column :sets, :start_offset, :integer
  end
end
