# frozen_string_literal: true

module Lml
  class AdminUser < ApplicationRecord
    devise(:database_authenticatable, :recoverable, :rememberable, :validatable)

    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at email id time_zone id_value updated_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    validates(
      :time_zone,
      inclusion: {
        in: Lml::Timezone::CANONICAL_TIMEZONES,
        message: "invalid time zone",
      },
    )
  end
end
