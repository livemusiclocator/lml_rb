class AddInstagramToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :instagram, :string
  end
end
