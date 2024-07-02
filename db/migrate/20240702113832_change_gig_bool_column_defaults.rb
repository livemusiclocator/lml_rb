class ChangeGigBoolColumnDefaults < ActiveRecord::Migration[7.1]
  def change
    change_column_default :gigs, :hidden, false
    change_column_default :gigs, :checked, false
  end
end
