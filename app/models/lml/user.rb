# frozen_string_literal: true

module Lml
  class User < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[email display_name created_at admin]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[proposals managed_venues managed_acts api_tokens]
    end

    devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable

    has_many :proposals, class_name: "Lml::Proposal", dependent: :destroy
    has_many :venue_managers, class_name: "Lml::VenueManager", dependent: :destroy
    has_many :managed_venues, through: :venue_managers, source: :venue
    has_many :act_managers, class_name: "Lml::ActManager", dependent: :destroy
    has_many :managed_acts, through: :act_managers, source: :act
    has_many :api_tokens, class_name: "Lml::ApiToken", dependent: :destroy

    scope :admins, -> { where(admin: true) }

    # Being an admin is the whole of the admin API's authority - there are no
    # finer grained roles, so granting it hands over every endpoint at once.
    def manages_venue?(venue)
      managed_venues.exists?(venue.id)
    end

    def manages_act?(act)
      managed_acts.exists?(act.id)
    end

    def manager?
      venue_managers.exists? || act_managers.exists?
    end
  end
end
