class AddTimeZoneToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :time_zone, :string
  end
end
