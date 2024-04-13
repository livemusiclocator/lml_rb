class CreatePrices < ActiveRecord::Migration[7.1]
  def change
    create_table :prices, id: :uuid do |t|
      t.uuid :gig_id
      t.integer :cents
      t.string :description

      t.timestamps
    end
  end
end
