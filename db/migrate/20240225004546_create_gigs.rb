class CreateGigs < ActiveRecord::Migration[7.1]
  def change
    create_table :gigs, id: :uuid do |t|
      t.string :name
      t.date :date
      t.timestamp :start_time
      t.timestamp :finish_time

      t.timestamps
    end
  end
end
