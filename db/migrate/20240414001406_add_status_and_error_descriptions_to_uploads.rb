class AddStatusAndErrorDescriptionsToUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :uploads, :status, :string
    add_column :uploads, :error_description, :text
  end
end
