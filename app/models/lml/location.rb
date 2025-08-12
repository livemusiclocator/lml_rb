module Lml
  class Location < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at id internal_identifier latitude longitude name updated_at]
    end
    validates :internal_identifier, presence: true, uniqueness: true
    validates :name, presence: true
    validates :latitude, presence: true,
                         numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
    validates :longitude, presence: true,
                          numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  end
end
