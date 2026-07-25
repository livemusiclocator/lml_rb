class AddUsernameToAdminUser < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :username, :string
    execute "UPDATE admin_users SET username = email"
  end
end
