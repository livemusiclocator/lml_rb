# frozen_string_literal: true

module Web
  class TourismRegion < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at name updated_at]
    end

    has_many :venues, class_name: "Lml::Venue", dependent: :nullify

    validates :name, presence: true
    validates :internal_identifier, presence: true, uniqueness: true
  end
end
