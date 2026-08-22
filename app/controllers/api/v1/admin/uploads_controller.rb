# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Bulk gig creation from the clipper format - the same path the ActiveAdmin
      # upload form takes, so anything that works when pasted into the admin form
      # works here.
      #
      # Processing is synchronous, which matches the admin form and means the
      # caller finds out whether their content parsed. The cost is that a large
      # upload can run into Heroku's request timeout - see PROCESSING_LIMIT.
      class UploadsController < BaseController
        WRITABLE = %i[content source venue_id].freeze

        # Entries with an internal_description trigger one OpenAI call each for
        # genre suggestions, so a big upload can outrun the 30 second router
        # timeout. Well under what one venue's week looks like.
        PROCESSING_LIMIT = 100

        def index
          scope = Lml::Upload.order(created_at: :desc)
          scope = scope.filter_by_source(params[:source]) if params[:source].present?

          render json: {
            uploads: paginate(scope).map { |upload| serialize(upload) },
            meta: pagination_meta(scope),
          }
        end

        def show
          render json: { upload: serialize(Lml::Upload.find(params[:id]), with_gigs: true) }
        end

        def create
          upload = Lml::Upload.new(upload_params.merge(format: "clipper"))
          return render_invalid(upload) unless upload.valid?
          return too_many_entries(upload) if entry_count(upload) > PROCESSING_LIMIT

          upload.save!
          upload.process!

          respond_to_processing(upload.reload)
        end

        private

        def respond_to_processing(upload)
          # A failed upload is still a record worth keeping and worth returning -
          # its id and error_description are how a caller fixes the content and
          # tries again. Clipper stops at the first bad entry, so anything before
          # it has already been applied; re-sending corrected content is safe
          # because gigs are matched on name, date and venue.
          return render json: { upload: serialize(upload, with_gigs: true) }, status: :created unless
            upload.status == "Failed"

          # Carries `error` as well as the upload, so a client can keep one rule -
          # every non 2xx response has an `error` string - and still get at the id
          # and the partial result.
          render json: {
            error: upload.error_description,
            upload: serialize(upload, with_gigs: true),
          }, status: :unprocessable_content
        end

        def too_many_entries(upload)
          render_error(
            :unprocessable_content,
            "That upload has #{entry_count(upload)} entries and the limit is #{PROCESSING_LIMIT}. " \
            "Split it up - processing happens inside the request.",
          )
        end

        def entry_count(upload)
          Lml::Processors::ClipperParser.extract_entries(upload.content.to_s.lines).length
        end

        def upload_params
          params.require(:upload).permit(*WRITABLE)
        end

        def serialize(upload, with_gigs: false)
          serialized = upload.slice(:id, :source, :format, :status, :venue_id, :created_at)
                             .merge(error_description: upload.error_description.presence)
          return serialized unless with_gigs

          serialized.merge(content: upload.content, gigs: gigs_for(upload))
        end

        # The gigs this upload created or last touched. Entries it deleted are
        # gone, so they cannot appear here.
        def gigs_for(upload)
          Lml::Gig.where(upload: upload).order(:date, :start_offset).includes(:venue).map do |gig|
            {
              id: gig.id,
              name: gig.name,
              date: gig.date,
              start_time: gig.start_time,
              status: gig.status,
              venue: gig.venue && { id: gig.venue.id, name: gig.venue.name },
            }
          end
        end
      end
    end
  end
end
