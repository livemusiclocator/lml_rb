class RemoveColumnFromFromSets < ActiveRecord::Migration[7.1]
  def change
    remove_column :sets, :from
  end
end
