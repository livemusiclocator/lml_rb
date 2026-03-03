class AddEmailToActs < ActiveRecord::Migration[8.1]
  def change
    add_column :acts, :email, :string
  end
end
