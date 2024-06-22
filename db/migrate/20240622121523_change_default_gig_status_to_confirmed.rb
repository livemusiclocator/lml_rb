# frozen_string_literal: true

class ChangeDefaultGigStatusToConfirmed < ActiveRecord::Migration[7.1]
  def change
    change_column_default :gigs, :status, "confirmed"
  end
end
