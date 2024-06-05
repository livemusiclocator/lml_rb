class AddStageToSets < ActiveRecord::Migration[7.1]
  def change
    add_column :sets, :stage, :string
  end
end
