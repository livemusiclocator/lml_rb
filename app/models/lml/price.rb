module Lml
  class Price < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      []
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    belongs_to :gig

    monetize :cents, as: "amount"

    def gig_label
      gig&.label
    end
  end
end
