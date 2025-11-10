# frozen_string_literal: true

module Lml
  module Processors
    module ClipperParser
      def self.extract_entries(lines)
        # TODO: maybe look at these rubocop issues and fix them?
        # rubocop:disable Style/MultilineBlockChain
        extract_line_groups(lines).map do |group|
          extract_entry(group)
        end.filter { |details| details.keys.any? }
        # rubocop:enable Style/MultilineBlockChain
      end

      def self.extract_line_groups(lines)
        lines.slice_before(/^---/).to_a
      end

      # TODO: maybe look at these rubocop issues and fix them?
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def self.extract_entry(lines)
        {}.tap do |details|
          lines.each do |line|
            next if line.strip.empty?

            key, *rest = line.chomp.strip.split(":")
            value = rest.join(":").strip
            key = key.downcase.gsub(" ", "_")

            case key
            when "acts"
              details[:sets] ||= []
              details[:sets] += value.split("|").map(&:strip)
            when "date", "gig_date"
              details[:date] = value
            when "category"
              details[:category] = value
            when "duration"
              details[:duration] = value
            when "finish_time"
              details[:finish_time] = value
            when "genre"
              details[:genre_tags] ||= []
              details[:genre_tags] << value unless value.blank?
            when "id"
              details[:id] = value
            when "information"
              details[:information_tags] ||= []
              details[:information_tags] << value unless value.blank?
            when "internal_description"
              details[:internal_description] = value
            when "name", "gig_name"
              details[:name] = value
            when "price"
              details[:prices] ||= []
              details[:prices] << value
            when "series"
              details[:series] = value
            when "set"
              details[:sets] ||= []
              details[:sets] << value
            when "start_time", "gig_start_time", "time"
              details[:start_time] = value
            when "status"
              details[:status] = value
            when "tickets", "ticketing_url"
              details[:ticketing_url] = value
            when "venue_id"
              details[:venue_id] = value
            when "url", "gig_url"
              details[:url] = value
            when "weeks"
              details[:weeks] = value.to_i
            when "ticket_status"
              details[:ticket_status] = value
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
