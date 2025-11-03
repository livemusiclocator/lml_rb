class AddRymToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :rym, :string
  end
end
