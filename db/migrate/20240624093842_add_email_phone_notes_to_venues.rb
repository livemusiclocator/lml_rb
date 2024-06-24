class AddEmailPhoneNotesToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :email, :string
    add_column :venues, :phone, :string
    add_column :venues, :notes, :text
  end
end
