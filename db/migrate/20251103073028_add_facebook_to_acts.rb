class AddFacebookToActs < ActiveRecord::Migration[8.0]
  def change
    add_column :acts, :facebook, :string
  end
end
