# frozen_string_literal: true

module Lml
  # Applies venue blocks (see Processors::VenueBlocks) and answers with the same
  # blocks, each given a `result:` line and, when it failed, an `error:` line.
  #
  # Every block is tried, unlike a clipper upload, which stops at the first bad
  # entry: one typo'd venue should not hold back the rest of a long file. Each
  # block is saved on its own, so a failure leaves the others applied, and
  # sending the corrected response again is safe - a block that already holds
  # comes back `unchanged`.
  #
  # Nothing is kept. The response is the record of what happened, and the ids
  # in it are what to send next time.
  class VenueBulkUpdate
    LIMIT = 500

    UPDATED = "updated"
    UNCHANGED = "unchanged"
    NOT_FOUND = "not_found"
    INVALID = "invalid"

    def initialize(content, fields:)
      @blocks = Processors::VenueBlocks.parse(content)
      @fields = fields.map(&:to_s)
    end

    def entry_count
      @blocks.count { |block| !block.empty? }
    end

    def too_big?
      entry_count > LIMIT
    end

    def call
      out = StringIO.new
      @blocks.each { |block| out.write(answer(block)) }
      out.string
    end

    private

    def answer(block)
      return block.lines.join if block.empty?

      result, error, venue, merged_from = apply(block)
      write(block, result: result, error: error, id: venue&.id, merged_from: merged_from)
    end

    def apply(block)
      return [INVALID, block.problems.join("; ")] if block.problems.any?
      return [INVALID, "every block needs the id of the venue it changes"] if block.id.blank?

      venue, merged_from = find(block.id)
      return [NOT_FOUND, "no venue has the id #{block.id}"] unless venue

      attributes, problems = attributes_for(block.fields.except("id"))
      return [INVALID, problems.join("; "), venue, merged_from] if problems.any?

      venue.assign_attributes(attributes)
      return [UNCHANGED, nil, venue, merged_from] unless venue.changed?
      return [INVALID, venue.errors.full_messages.join("; "), venue, merged_from] unless venue.save

      [UPDATED, nil, venue, merged_from]
    end

    # A venue merged into another no longer exists, but its id still names one:
    # the survivor, which keeps the ids of everything merged into it.
    def find(id)
      return [nil, nil] unless id.match?(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)

      venue = Venue.find_by(id: id)
      return [venue, nil] if venue

      survivor = Venue.where("? = ANY(merged_venue_ids)", id).first
      [survivor, survivor && id]
    end

    def attributes_for(fields)
      attributes = {}
      problems = []

      fields.each do |key, value|
        value = value.presence
        case key
        when "tourism_region", "tourism_region_id"
          region, problem = tourism_region(key, value)
          problem ? problems << problem : attributes["tourism_region"] = region
        when "tags"
          attributes["tags"] = value.to_s.split("|").map(&:strip).compact_blank
        when *@fields
          problem = number_problem(key, value)
          problem ? problems << problem : attributes[key] = value
        else
          problems << "#{key} is not a field that can be set"
        end
      end

      [attributes, problems]
    end

    # Rails reads `capacity: lots` as nil, which would quietly clear the column
    # rather than refuse the typo.
    def number_problem(key, value)
      return if value.nil?

      case Venue.type_for_attribute(key).type
      when :integer then "#{key} must be a whole number" unless value.match?(/\A-?\d+\z/)
      when :float, :decimal then "#{key} must be a number" unless value.match?(/\A-?\d+(\.\d+)?\z/)
      end
    end

    # By name, so a person can write `tourism_region: Melbourne`, or by
    # internal identifier or id for a script holding one of those.
    def tourism_region(key, value)
      return [nil, nil] if value.nil?

      region =
        if key == "tourism_region_id"
          Web::TourismRegion.find_by(id: value) if value.match?(/\A\h{8}-(\h{4}-){3}\h{12}\z/)
        else
          Web::TourismRegion
            .find_by("LOWER(name) = LOWER(:value) OR LOWER(internal_identifier) = LOWER(:value)", value: value)
        end
      region ? [region, nil] : [nil, "there is no tourism region #{value.inspect}"]
    end

    # The block as it was sent, with any result lines from an earlier response
    # dropped and this one's added. A block that arrived under a merged venue's id
    # goes back under the survivor's, with the old id kept beside it.
    def write(block, result:, error:, id:, merged_from:)
      lines = block.lines.reject { |line| response_line?(line) }
      lines = lines.map { |line| id_line?(line) ? "id: #{id}\n" : line } if merged_from
      lines[-1] = "#{lines[-1]}\n" unless lines.empty? || lines[-1].end_with?("\n")

      trailing = []
      trailing.unshift(lines.pop) while lines.any? && lines.last.strip.empty?

      added = []
      added << "merged_from: #{merged_from}\n" if merged_from
      added << "result: #{result}\n"
      added << "error: #{error}\n" if error
      [*lines, *added, *trailing].join
    end

    def response_line?(line)
      key = line.split(":", 2).first.to_s.strip.downcase
      line.include?(":") && Processors::VenueBlocks::RESPONSE_KEYS.include?(key)
    end

    def id_line?(line)
      line.split(":", 2).first.to_s.strip.casecmp?("id")
    end
  end
end
