# frozen_string_literal: true

module Lml
  class Proposal < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[status proposed_type note reviewer_note created_at reviewed_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[user reviewed_by]
    end

    belongs_to :user, class_name: "Lml::User"
    belongs_to :target, polymorphic: true, optional: true
    belongs_to :reviewed_by, class_name: "Lml::AdminUser", optional: true

    enum :status, { pending: 0, approved: 1, rejected: 2 }

    validates :proposed_attributes, presence: true
    validates :proposed_type, presence: true, if: -> { target.nil? }

    scope :for_target, ->(record) { where(target: record) }

    def new_record_proposal?
      target.nil?
    end

    def amendment?
      target.present?
    end

    def approve!(admin:, note: nil)
      return false unless pending?

      if amendment?
        target.update!(proposed_attributes)
      elsif proposed_type == "Lml::Gig"
        venue = Lml::Venue.find(proposed_attributes["venue_id"])
        details = proposed_attributes.except("venue_id", "name", "date")
        Lml::Gig.find_or_create_gig(
          name: proposed_attributes["name"],
          date: proposed_attributes["date"],
          venue: venue,
          details: details,
        )
      end
      update!(
        status: :approved,
        reviewed_by: admin,
        reviewed_at: Time.current,
        reviewer_note: note,
      )
      # ProposalMailer.approved(self).deliver_now
      true
    end

    def reject!(admin:, note: nil)
      return false unless pending?

      update!(status: :rejected, reviewed_by: admin, reviewed_at: Time.current, reviewer_note: note)
      # ProposalMailer.rejected(self).deliver_now
      true
    end

    def target_label
      target&.try(:label) || target&.try(:name) || target&.to_s || proposed_type
    end
  end
end
