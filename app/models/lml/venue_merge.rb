# frozen_string_literal: true

# One method per column group, which is what pushes this past the class length limit - the same
# trade Lml::Gig makes, and the alternative is a second class that only exists to satisfy the metric.
# rubocop:disable Metrics/ClassLength
module Lml
  # Folds a duplicate venue into the one we are keeping, which is the only way to get rid of a
  # duplicate now that Lml::Venue#gigs refuses to be deleted out from under its gigs.
  #
  # The duplicate's gigs, uploads and managers move across; the survivor picks up every column it
  # had no value of its own for; anything the duplicate knew *differently* goes into the survivor's
  # notes rather than being dropped on the floor; and then the duplicate is destroyed, which by
  # then it can be, because it has no gigs left.
  #
  # No UI in here on purpose - venue admin lives in ActiveAdmin today and is meant to move to
  # backstage, and a merge is the same merge from either.
  class VenueMerge
    class Error < StandardError; end

    # Lml::Place writes these three as a unit and they are misleading apart: a place id without the
    # components it resolved would claim this venue matched an address it never did. So they cross
    # together or not at all, gated on the components alone - the rule Lml::Place#attributes_for
    # already applies for the same reason.
    PLACE_COLUMNS = %w[google_place_id address_components google_business_status].freeze

    # A latitude without its longitude locates nothing, so this pair crosses as a unit too.
    POINT_COLUMNS = %w[latitude longitude].freeze

    # Filled in where the survivor is blank, recorded in its notes where it holds something else.
    # `name` is in here deliberately: a duplicate's spelling is usually the reason it got created
    # twice, so it is worth keeping rather than losing with the record.
    SCALAR_COLUMNS = %w[
      address
      capacity
      email
      facebook_url
      instagram_url
      lga
      location
      location_url
      name
      phone
      postcode
      time_zone
      vibe
      website
    ].freeze

    Result = Struct.new(:gigs, :uploads, :managers, :filled_in, :discarded, keyword_init: true)

    def initialize(survivor:, duplicate:)
      @survivor = survivor
      @duplicate = duplicate
      @filled_in = []
      @discarded = []
    end

    def call
      raise Error, "a venue cannot be merged into itself" if @survivor.id == @duplicate.id

      Lml::Venue.transaction do
        fold_in_columns
        @survivor.save!

        moved = move_associations
        # The duplicate's gigs went out from under a possibly loaded association, and
        # restrict_with_error reads that cache rather than the table.
        @duplicate.reload.destroy!

        Result.new(**moved, filled_in: @filled_in, discarded: @discarded)
      end
    end

    private

    # Notes last, so the record it writes has the whole discarded list to draw on.
    def fold_in_columns
      SCALAR_COLUMNS.each { |column| fold_in_scalar(column) }
      fold_in_place
      fold_in_point
      fold_in_tags
      fold_in_researcher
      fold_in_notes
    end

    def fold_in_scalar(column)
      theirs = @duplicate[column]
      return if theirs.blank?

      ours = @survivor[column]

      if ours.blank?
        @survivor[column] = theirs
        @filled_in << column
      elsif ours != theirs
        @discarded << "#{Lml::Venue.human_attribute_name(column)}: #{theirs.inspect}"
      end
    end

    def fold_in_place
      return if @duplicate.address_components.blank?

      if @survivor.address_components.blank?
        PLACE_COLUMNS.each { |column| @survivor[column] = @duplicate[column] }
        @filled_in.concat(PLACE_COLUMNS)
      elsif @survivor.address_identity != @duplicate.address_identity
        # Only the id: a components blob in a notes field helps nobody, and the id names the place
        # well enough to look it up again.
        @discarded << "Google place id: #{@duplicate.google_place_id.inspect}"
      end
    end

    def fold_in_point
      # Nil unless both halves are there, which is exactly the gate this wants.
      return if @duplicate.lat_lng.blank?

      if @survivor.lat_lng.blank?
        POINT_COLUMNS.each { |column| @survivor[column] = @duplicate[column] }
        @filled_in.concat(POINT_COLUMNS)
      elsif @survivor.lat_lng != @duplicate.lat_lng
        @discarded << "Lat lng: #{@duplicate.lat_lng.inspect}"
      end
    end

    # A tag list is a set, so the union loses nothing and there is no conflict to record.
    def fold_in_tags
      theirs = @duplicate.tags || []
      return if theirs.empty?

      ours = @survivor.tags || []
      merged = (ours + theirs).uniq
      return if merged == ours

      @survivor.tags = merged
      @filled_in << "tags"
    end

    # The researcher assignment is a work queue rather than a fact about the venue, so an
    # unassigned survivor inherits one and a differently assigned survivor keeps its own without
    # cluttering the notes over it.
    def fold_in_researcher
      return if @duplicate.admin_user_id.blank? || @survivor.admin_user_id.present?

      @survivor.admin_user_id = @duplicate.admin_user_id
      @filled_in << "admin_user_id"
    end

    def fold_in_notes
      @survivor.notes = [@survivor.notes.presence, merge_record.join("\n")].compact.join("\n\n")
    end

    def merge_record
      record = ["Merged #{@duplicate.name.inspect} on #{Date.current.iso8601}."]
      record << "Discarded from it: #{@discarded.join("; ")}." if @discarded.any?
      record << @duplicate.notes.strip if @duplicate.notes.present?
      record
    end

    def move_associations
      now = Time.current

      gigs = Lml::Gig.where(venue_id: @duplicate.id).update_all(venue_id: @survivor.id, updated_at: now)
      # Moved rather than deleted: a gig's upload_id is where it came from, and there is no foreign
      # key to stop that pointing at nothing.
      uploads = Lml::Upload.where(venue_id: @duplicate.id).update_all(venue_id: @survivor.id, updated_at: now)

      { gigs: gigs, uploads: uploads, managers: move_managers(now) }
    end

    # venue_managers is unique on [user_id, venue_id], so a user who manages both venues cannot have
    # their row moved. Theirs is left to be destroyed with the duplicate - they manage the survivor
    # either way, which is the whole point.
    def move_managers(now)
      already_managing = Lml::VenueManager.where(venue_id: @survivor.id).select(:user_id)

      Lml::VenueManager
        .where(venue_id: @duplicate.id)
        .where.not(user_id: already_managing)
        .update_all(venue_id: @survivor.id, updated_at: now)
    end
  end
end
# rubocop:enable Metrics/ClassLength
