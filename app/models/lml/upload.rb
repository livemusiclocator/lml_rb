# frozen_string_literal: true

module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[
        source
        venue_id
      ]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    belongs_to :venue, optional: true
    # Who sent it, where it came through a backstage user's API token.
    belongs_to :user, class_name: "Lml::User", optional: true
    # gigs.upload_id records which upload a gig arrived on, and Lml::Processors::Clipper reassigns
    # it every time a gig is processed again, so it is provenance rather than ownership. The column
    # has no foreign key, so nothing was stopping it dangling once an upload went. Nullify rather
    # than restrict: deleting a processed upload should not be gated on the gigs it happened to
    # create, and those gigs stand on their own afterwards.
    has_many :gigs,
      class_name: "Lml::Gig",
      foreign_key: :upload_id,
      inverse_of: :upload,
      dependent: :nullify

    # Processing happens inside the request, and entries with an
    # internal_description each make an OpenAI call for genre suggestions, so a
    # big upload can outrun Heroku's 30 second router timeout. Well under what
    # one venue's week looks like.
    PROCESSING_LIMIT = 100

    def entry_count
      Lml::Processors::ClipperParser.extract_entries(content.to_s.lines).length
    end

    def too_big?
      entry_count > PROCESSING_LIMIT
    end

    def venue_label
      venue&.label
    end

    def process!
      return if content.blank?

      # Clipper assigns Time.zone per entry and never puts it back, and Time.zone
      # is thread local - Rails does not reset it between requests. Without this,
      # processing an upload leaves every later request served by that thread
      # rendering times in the last venue's zone. use_zone restores what was
      # there when the block ends.
      processor = Lml::Processors::Clipper.new(self)
      Time.use_zone(Time.zone) do
        processor.process!
      end
    ensure
      update_column(:entry_gig_ids, processor.entry_gig_ids) if processor && persisted?
    end

    # The content as it was sent, with each entry given the id of the gig it
    # became. Send this back and every entry updates its gig by id, whatever
    # has been renamed since - where the content as sent matches on name, date
    # and venue, and a gig renamed in review would come back as a second copy.
    #
    # Left alone: an entry that already had an id, one that became several gigs
    # (`weeks`), and one that deleted its gig or was never reached.
    def content_with_ids
      ids = Array(entry_gig_ids)
      index = -1
      Lml::Processors::ClipperParser.extract_line_groups(content.to_s.lines).map do |group|
        details = Lml::Processors::ClipperParser.extract_entry(group)
        next group.join if details.keys.none?

        index += 1
        made = Array(ids[index])
        next group.join unless made.length == 1 && details[:id].blank?

        line = "id: #{made.first}\n"
        group.first.to_s.start_with?("---") ? [group.first, line, *group.drop(1)].join : [line, *group].join
      end.join
    end

    scope :filter_by_source, ->(source) { where(source: source) }
  end
end
