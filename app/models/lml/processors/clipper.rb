# frozen_string_literal: true

module Lml
  module Processors
    # An upload's clipper content applied entry by entry, stopping at the first
    # entry that fails and recording why on the upload. Entries before it stay
    # applied. Each entry is a ClipperEntry, which the admin API's bulk update
    # shares - that one carries on past a failure instead.
    class Clipper
      # The gig ids each entry ended up as, in entry order - several for an
      # entry with `weeks`, none for one that deleted its gig. Kept for
      # Upload#content_with_ids.
      attr_reader :entry_gig_ids

      def initialize(upload)
        @upload = upload
        @entry_gig_ids = []
      end

      def process!
        ClipperParser.extract_entries(@upload.content.lines).each_with_index do |details, index|
          return fail! unless apply(details, index)
        end

        @upload.save!
      end

      private

      def apply(details, index)
        outcome = entry(details).apply!
        @entry_gig_ids << outcome.gig_ids
        if outcome.result != ClipperEntry::DELETED
          @upload.status = "Succeeded"
          @upload.error_description = ""
        end
        true
      rescue ClipperEntry::Failed => e
        @failure = "#{index + 1}: #{e.message}"
        false
      end

      def entry(details)
        ClipperEntry.new(
          details,
          default_venue: @upload.venue,
          source: @upload.source,
          upload: @upload,
          uploaded_by: @upload.user,
        )
      end

      def fail!
        @upload.status = "Failed"
        @upload.error_description = @failure
        @upload.save!
        1
      end
    end
  end
end
