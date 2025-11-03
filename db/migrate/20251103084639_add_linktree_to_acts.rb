class AddLinktreeToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :linktree, :string
  end
end
