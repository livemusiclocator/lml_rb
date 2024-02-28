class AddHeadlineActToGigs < ActiveRecord::Migration[7.1]
  def change
    add_reference :gigs, :headline_act, type: :uuid, foreign_key: { to_table: :acts }
  end
end
