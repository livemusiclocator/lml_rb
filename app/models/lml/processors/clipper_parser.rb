module Lml
  module Processors
    module ClipperParser
      def self.extract_entries(lines)
        extract_line_groups(lines).map { |group| extract_entry(group) }
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
            when "act", "acts"
              details[:acts] = value.split("|").map(&:strip)
            when "date", "gig_date", "gig_start_date"
              details[:date] = Date.parse(value)
            when "name", "gig_name"
              details[:name] = value
            when "price", "prices"
              details[:prices] = value.split("|").map(&:strip)
            when "tag", "tags"
              details[:tags] = value.split("|").map(&:strip)
            when "tickets", "ticketing_url"
              details[:ticketing_url] = value
            when "time", "start_time", "gig_start_time"
              details[:time] = Time.parse(value)
            when "venue", "venue_name"
              details[:venue] = value
            when "url", "gig_url"
              details[:url] = value
            end
          end
        end
      end
    end
  end
end
