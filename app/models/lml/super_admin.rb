# frozen_string_literal: true

module Lml
  # The ActiveAdmin login at api.lml.live. Not the same thing as a backstage
  # user with the `admin` flag (Lml::User#admin?), which is what an admin
  # means everywhere else, the admin API's tokens included.
  #
  # It was Lml::AdminUser, which read as though it were that flag. Renamed in
  # the code only: the table is still admin_users, along with venues.admin_user_id
  # and the devise scope (authenticate_admin_user!, current_admin_user). Renaming
  # those is a migration in two deploys for a table that goes away with
  # ActiveAdmin, as admins move to backstage.
  class SuperAdmin < ApplicationRecord
    self.table_name = "admin_users"

    devise(:database_authenticatable, :recoverable, :rememberable, :validatable)

    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at email username id time_zone id_value updated_at last_active_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[venues]
    end

    has_many :venues, class_name: "Lml::Venue", foreign_key: :admin_user_id, dependent: :nullify
    # proposals.reviewed_by_id has a foreign key but had no association on this side, so deleting an
    # super admin who had ever reviewed anything was a 500. Nullify rather than restrict: the review
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
