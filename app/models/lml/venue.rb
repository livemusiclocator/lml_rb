module Lml
  class Venue < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name location]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    has_many :gigs

    def label
      "#{name} (#{location})"
    end
  end
end
