# frozen_string_literal: true

module Lml
  class AdminUser < ApplicationRecord
    devise(:database_authenticatable, :recoverable, :rememberable, :validatable)

    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at email id time_zone id_value updated_at last_active_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[venues]
    end

    has_many :venues, class_name: "Lml::Venue", foreign_key: :admin_user_id, dependent: :nullify

    validates(
      :time_zone,
      inclusion: {
        in: Lml::Timezone::CANONICAL_TIMEZONES,
        message: "invalid time zone",
      },
    )
  end
end
