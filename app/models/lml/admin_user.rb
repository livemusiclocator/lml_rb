# frozen_string_literal: true

module Lml
  class AdminUser < ApplicationRecord
    devise(:database_authenticatable, :recoverable, :rememberable, :validatable)

    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at email username id time_zone id_value updated_at last_active_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[venues]
    end

    has_many :venues, class_name: "Lml::Venue", foreign_key: :admin_user_id, dependent: :nullify
    # proposals.reviewed_by_id has a foreign key but had no association on this side, so deleting an
    # admin user who had ever reviewed anything was a 500. Nullify rather than restrict: the review
    # itself - its status, reviewed_at and reviewer_note - is the part worth keeping, and this
    # account is meant to stop existing once admins move to backstage.
    has_many :reviewed_proposals,
      class_name: "Lml::Proposal",
      foreign_key: :reviewed_by_id,
      inverse_of: :reviewed_by,
      dependent: :nullify

    validates(
      :time_zone,
      inclusion: {
        in: Lml::Timezone::CANONICAL_TIMEZONES,
        message: "invalid time zone",
      },
    )
  end
end
