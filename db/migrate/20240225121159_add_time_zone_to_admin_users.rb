class AddTimeZoneToAdminUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_users, :time_zone, :string
  end
end
