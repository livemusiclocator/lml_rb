# frozen_string_literal: true

module Lml
  class VenueManager < ApplicationRecord
    belongs_to :user, class_name: "Lml::User"
    belongs_to :venue, class_name: "Lml::Venue"
  end
end
