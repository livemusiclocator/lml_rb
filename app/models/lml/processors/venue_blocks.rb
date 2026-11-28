# frozen_string_literal: true

module Lml
  module Processors
    # Venues as `key: value` blocks separated by `---` lines - the shape clipper
    # uses for gigs, so a person who can edit one can edit the other.
    #
    # What the export writes is what the bulk update reads, so a venue can go out,
    # be edited in a text editor and come back in. Only the fields a caller may
    # write are exported, and only the ones with a value: a key left out of a
    # block leaves that field alone, and `key:` with nothing after it clears it.
    module VenueBlocks
      SEPARATOR = /\A---/

      # Written into a block by the bulk update's response, and skipped when that
      # response is read back in - so a response can be corrected and resent whole.
      RESPONSE_KEYS = %w[result error merged_from].freeze

      # The only fields that can run to several lines. Each line is written as its
      # own `notes:` line and joined back together on the way in, so a round trip
      # keeps the line breaks.
      MULTILINE = %w[notes vibe].freeze

      Block = Struct.new(:lines, :fields, :problems, keyword_init: true) do
        def empty?
          fields.empty? && problems.empty?
        end

        def id
          fields["id"]
        end
      end

      def self.parse(content)
        content.to_s.lines.slice_before(SEPARATOR).map { |lines| parse_block(lines) }
      end

      def self.parse_block(lines)
        block = Block.new(lines: lines, fields: {}, problems: [])
        lines.each { |line| read_line(block, line.strip) }
        block
      end

      def self.read_line(block, text)
        return if text.empty? || text.start_with?("#") || text.match?(SEPARATOR)

        key, separator, value = text.partition(":")
        return block.problems << "could not read #{text.inspect} - every line is `key: value`" if separator.empty?

        key = key.strip.downcase.tr(" ", "_")
        add(block, key, value.strip) unless RESPONSE_KEYS.include?(key)
      end

      def self.add(block, key, value)
        if !block.fields.key?(key)
          block.fields[key] = value
        elsif MULTILINE.include?(key)
          block.fields[key] = [block.fields[key], value].join("\n")
        else
          block.problems << "#{key} is given more than once"
        end
      end

      # `fields` is the caller's writable allowlist, in the order to write them.
      def self.serialise(venues, fields:)
        out = StringIO.new
        venues.each { |venue| serialise_venue(out, venue, fields) }
        out.string
      end

      def self.serialise_venue(out, venue, fields)
        out.puts "---"
        row(out, "id", venue.id)
        fields.map(&:to_s).each { |field| write_field(out, venue, field) }
      end

      def self.write_field(out, venue, field)
        case field
        when "tourism_region_id" then row(out, "tourism_region", venue.tourism_region&.name)
        when "tags" then row(out, "tags", (venue.tags || []).join(" | "))
        when *MULTILINE then multiline(out, field, venue.public_send(field))
        else row(out, field, venue.public_send(field))
        end
      end

      # Blank lines inside the text are written too, as an empty `notes:` line,
      # so the text comes back exactly as it went out.
      def self.multiline(out, field, value)
        return if value.blank?

        value.to_s.strip.split(/\r?\n/).each { |line| out.puts "#{field}: #{line.strip}".rstrip }
      end

      def self.row(out, key, value)
        out.puts "#{key}: #{value}" unless value.blank?
      end
    end
  end
end
