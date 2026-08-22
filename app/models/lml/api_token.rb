# frozen_string_literal: true

module Lml
  # A bearer token identifying one admin to the admin API.
  #
  # Unlike the TOKENS shared secret (see TokenAccess) every token here has an
  # owner, a last used timestamp, an optional expiry and a revocation switch -
  # which is what makes it safe to put in front of endpoints that write.
  #
  # The secret itself is never stored. We keep a SHA-256 digest and look tokens
  # up by that digest, so the database does one index hit and no secret is ever
  # compared in ruby. SHA-256 with no stretching is the right call here because
  # the secret is 256 bits of `SecureRandom` rather than a human's password -
  # there is no dictionary to run against it.
  class ApiToken < ApplicationRecord
    # Greppable in a leak scan and recognisable in a support ticket.
    PREFIX = "lml_admin_"

    belongs_to :user, class_name: "Lml::User"

    validates :name, presence: true
    validates :token_digest, presence: true, uniqueness: true

    scope :active, lambda {
      where(revoked_at: nil).where(expires_at: nil).or(
        where(revoked_at: nil).where(expires_at: Time.current..),
      )
    }

    # Only ever populated on the request that issued the token - it is the one
    # chance the owner gets to copy it.
    attr_accessor :plaintext

    def self.issue!(user:, name:, expires_at: nil)
      secret = "#{PREFIX}#{SecureRandom.urlsafe_base64(32)}"
      token = create!(user: user, name: name, expires_at: expires_at, token_digest: digest(secret))
      token.plaintext = secret
      token
    end

    def self.digest(secret)
      Digest::SHA256.hexdigest(secret)
    end

    # Returns the token, or nil for anything we did not issue, have revoked, or
    # have let expire. Callers still have to decide whether the owner is allowed
    # to do what they are asking - this only answers "who is this".
    def self.authenticate(secret)
      return nil if secret.blank?

      active.find_by(token_digest: digest(secret))
    end

    def self.ransackable_attributes(_auth_object = nil)
      %w[name created_at last_used_at expires_at revoked_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[user]
    end

    def active?
      revoked_at.nil? && (expires_at.nil? || expires_at.future?)
    end

    def revoked?
      revoked_at.present?
    end

    def expired?
      expires_at.present? && expires_at.past?
    end

    def revoke!
      update!(revoked_at: Time.current) unless revoked?
    end

    # Deliberately skips validations and timestamps: this runs on every
    # authenticated request and must never be able to fail one.
    def record_use!
      update_column(:last_used_at, Time.current)
    end
  end
end
