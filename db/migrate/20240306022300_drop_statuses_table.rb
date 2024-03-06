class DropStatusesTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :statuses, force: :cascade
  end
end
