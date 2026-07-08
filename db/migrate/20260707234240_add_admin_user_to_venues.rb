class AddAdminUserToVenues < ActiveRecord::Migration[8.1]
  def change
    add_column :venues, :admin_user_id, :uuid
    add_index :venues, :admin_user_id
  end
end
