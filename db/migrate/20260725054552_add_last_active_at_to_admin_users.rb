class AddLastActiveAtToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :last_active_at, :datetime
  end
end
