# frozen_string_literal: true

class AddTicketStatusToGigs < ActiveRecord::Migration[7.1]
  def change
    create_enum :ticket_status, %w[selling_fast sold_out]

    change_table :gigs do |t|
      t.enum :ticket_status, enum_type: "ticket_status"
    end
  end
end
