module Lml
  class Venue < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      %w[name]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    has_many :gigs
  end
end
