module Lml
  class Price < ApplicationRecord
    def self.ransackable_attributes(auth_object = nil)
      []
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    def self.create_for_gig_from_line!(gig, line)
      amount, description = line.split("|").map(&:strip)
      return if amount.blank?

      Lml::Price.create(
        gig: gig,
        amount: amount,
        description: description,
      )
    end

    belongs_to :gig

    monetize :cents, as: "amount"

    def gig_label
      gig&.label
    end

    def line
      "#{amount.format} | #{description}"
    end
  end
end
