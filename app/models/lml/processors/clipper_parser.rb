# frozen_string_literal: true

module Lml
  module Processors
    module ClipperParser
      def self.extract_entries(lines)
        extract_line_groups(lines).map do |group|
          extract_entry(group)
        end.filter { |details| details.keys.count.positive? }
      end

      def self.extract_line_groups(lines)
        lines.slice_before(/^---/).to_a
      end

      def self.extract_entry(lines)
        {}.tap do |details|
          lines.each do |line|
            next if line.strip.empty?

            key, *rest = line.chomp.strip.split(":")
            value = rest.join(":").strip
            key = key.downcase.gsub(" ", "_")

            case key
            when "date"
              details[:date] = value
            when "category"
              details[:category] = value
            when "duration"
              details[:duration] = value
            when "genre"
              details[:genre_tags] ||= []
              details[:genre_tags] << value
            when "id"
              details[:id] = value
            when "information"
              details[:information_tags] ||= []
              details[:information_tags] << value
            when "name", "gig_name"
              details[:name] = value
            when "price"
              details[:prices] ||= []
              amount, description = value.split.map(&:strip)
              details[:prices] << {
                amount: amount,
                description: description,
              }
            when "series"
              details[:series] = value
            when "set"
              details[:sets] ||= []
              act_name, start_offset_time, duration, stage  = value.split("|").map(&:strip)
              details[:sets] << {
                act_name: act_name,
                start_offset_time: start_offset_time,
                duration: duration,
                stage: stage,
              }
            when "status"
              details[:status] = value
            when "tickets", "ticketing_url"
              details[:ticketing_url] = value
            when "time", "start_time", "gig_start_time"
              details[:time] = value
            when "url", "gig_url"
              details[:url] = value
            end
          end
        end
      end
    end
  end
end
