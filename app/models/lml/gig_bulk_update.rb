# frozen_string_literal: true

module Lml
  # Clipper content applied a block at a time, answered with the same blocks,
  # each given a `result:` line - created, updated, deleted, not_found or
  # invalid - and an `error:` line when it failed. The admin API's way in for
  # gigs; the upload forms keep using Lml::Upload.
  #
  # Unlike an upload, nothing is kept and nothing stops early: every block is
  # tried, each in its own transaction, so one bad entry holds back nothing
  # else and a block that fails halfway through its `weeks` leaves no half of
  # itself behind. Who sent each gig goes on the gig (gigs.uploaded_by), which is
  # what the review queue starts from.
  #
  # A block that became a single gig comes back with that gig's `id:`, so
  # sending the response again updates by id even after a rename in review.
  # Unknown keys are ignored on the way in, so the result lines are too.
  class GigBulkUpdate
    # Entries with an internal_description each make an OpenAI call, inside
    # the request - see Lml::Upload::PROCESSING_LIMIT.
    LIMIT = Lml::Upload::PROCESSING_LIMIT

    RESPONSE_KEYS = %w[result error gig_ids].freeze

    def initialize(content, venue:, source:, user:)
      @groups = Processors::ClipperParser.extract_line_groups(content.to_s.lines)
      @venue = venue
      @source = source
      @user = user
    end

    def entry_count
      @groups.count { |group| entry(group).keys.any? }
    end

    def too_big?
      entry_count > LIMIT
    end

    def call
      # ClipperEntry sets Time.zone per entry, and Time.zone is thread local.
      Time.use_zone(Time.zone) { @groups.map { |group| answer(group) }.join }
    end

    private

    def entry(group)
      Processors::ClipperParser.extract_entry(group)
    end

    def answer(group)
      details = entry(group)
      return group.join if details.keys.none?

      result, error, gig_ids = apply(details)
      write(group, details, result, error, gig_ids || [])
    end

    def apply(details)
      outcome = ApplicationRecord.transaction do
        Processors::ClipperEntry.new(details, default_venue: @venue, source: @source, uploaded_by: @user).apply!
      end
      [outcome.result, nil, outcome.gig_ids]
    rescue Processors::ClipperEntry::Failed => e
      # Deleting a gig that is already gone is done, not a failure, so a
      # response holding a delete can be sent again.
      return [Processors::ClipperEntry::DELETED, nil, []] if e.result == "not_found" && details[:status] == "delete"

      [e.result, e.message, []]
    rescue ActiveRecord::RecordInvalid => e
      ["invalid", e.record.errors.full_messages.join("; "), []]
    end

    def write(group, details, result, error, gig_ids)
      lines = group.reject { |line| response_line?(line) }
      lines[-1] = "#{lines[-1]}\n" unless lines.empty? || lines[-1].end_with?("\n")
      lines = with_id(lines, gig_ids.first) if details[:id].blank? && gig_ids.one? && (details[:weeks] || 1) == 1

      trailing = []
      trailing.unshift(lines.pop) while lines.any? && lines.last.strip.empty?

      added = []
      added << "gig_ids: #{gig_ids.join(", ")}\n" if gig_ids.many?
      added << "result: #{result}\n"
      added << "error: #{error}\n" if error
      [*lines, *added, *trailing].join
    end

    # Straight after the separator, where Upload#content_with_ids puts it.
    def with_id(lines, id)
      line = "id: #{id}\n"
      lines.first.to_s.start_with?("---") ? [lines.first, line, *lines.drop(1)] : [line, *lines]
    end

    def response_line?(line)
      key, separator, = line.partition(":")
      !separator.empty? && RESPONSE_KEYS.include?(key.strip.downcase)
    end
  end
end
