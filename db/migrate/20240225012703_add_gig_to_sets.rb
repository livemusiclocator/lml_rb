class AddGigToSets < ActiveRecord::Migration[7.1]
  def change
    add_reference :sets, :gig, type: :uuid, foreign_key: true
  end
end
