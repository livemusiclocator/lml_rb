# frozen_string_literal: true

module Backstage
  # Clipper uploads, for admins: the list, one upload and what it did, and
  # pasting a new one in. The same processing the admin API and ActiveAdmin's
  # form use, so content that works in one works in all three.
  #
  # An upload made here belongs to whoever made it, the same as one sent with
  # their API token - which is what puts its gigs in their review queue.
  #
  # Reprocessing an old upload stays in ActiveAdmin for now: it rewrites every
  # gig the upload names, long after anybody looked at them.
  class UploadsController < ApplicationController
    before_action :require_admin!

    PER_PAGE = 50
    WHO = %w[mine everyone].freeze

    def index
      @who = WHO.include?(params[:who]) ? params[:who] : "mine"
      @source = params[:source].presence
      scope = Lml::Upload.includes(:venue, :user).order(created_at: :desc)
      scope = scope.where(user: current_user) if @who == "mine"
      scope = scope.where(source: @source) if @source
      @page = [params[:page].to_i, 1].max
      @uploads = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @more = @uploads.length > PER_PAGE
      @uploads = @uploads.first(PER_PAGE)
    end

    def show
      @upload = Lml::Upload.find(params[:id])
      @gigs = @upload.gigs.includes(:venue).order(:date, :start_offset)
    end

    def new
      @upload = Lml::Upload.new(source: "backstage")
    end

    def create
      @upload = Lml::Upload.new(upload_params.merge(format: "clipper", user: current_user))
      @upload.errors.add(:content, :blank) if @upload.content.blank?
      if @upload.too_big?
        @upload.errors.add(:content, "has #{@upload.entry_count} entries and the limit is " \
                                     "#{Lml::Upload::PROCESSING_LIMIT} - split it up")
      end
      return render(:new, status: :unprocessable_entity) if @upload.errors.any? || !@upload.save

      @upload.process!
      @upload.reload
      if @upload.status == "Failed"
        redirect_to backstage_upload_path(@upload), alert: "The upload failed: #{@upload.error_description}"
      else
        redirect_to backstage_upload_path(@upload), notice: "Uploaded #{helpers.pluralize(@upload.gigs.count, 'gig')}."
      end
    end

    private

    def upload_params
      params.require(:upload).permit(:content, :source, :venue_id)
    end
  end
end
