module Lml
  class Act < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name country location]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    def genre_list
      (genres || []).join(", ")
    end

    def genre_list=(value)
      self.genres = value.split(",").map(&:strip)
    end
  end
end
