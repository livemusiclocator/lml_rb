class AddFromToSets < ActiveRecord::Migration[7.1]
  def change
    add_column :sets, :from, :time
  end
end
