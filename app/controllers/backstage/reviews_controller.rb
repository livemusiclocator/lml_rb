# frozen_string_literal: true

module Backstage
  # Working through gigs nobody has checked yet, one screen a gig.
  #
  # Research uploads everything it finds straight into LML - named after the
  # event title, with the lineup it guessed at in proposed_acts and the genres
  # suggest_tags! guessed at in proposed_genre_tags - and leaves the tidying to
  # here. The gigs are live the whole time; a gig nobody gets to is still a gig,
  # just an unconfirmed one.
  #
  # Each gig gets one of three answers, and every one moves on to the next:
  #
  # - save: confirm the name, acts and genres, and mark it checked
  # - hide: not a gig (karaoke, a market), so hide it and mark it checked
  # - skip: come back to it later
  #
  # Skipped gigs are remembered in the session, so skipping does not land on the
  # same gig again. The list starts over from the index.
  #
  # It starts from the gigs you sent in, by upload or the admin API's bulk update
  # (gigs.uploaded_by) - `who=mine`, the default -
  # because every gig LML holds starts out unchecked, and the whole of that is
  # not anybody's to work through. `who=everyone` is the rest of it.
  class ReviewsController < ApplicationController
    before_action :require_admin!

    FILTERS = %i[who source upload_id venue_id location].freeze
    WHO = %w[mine everyone].freeze
    SKIPPED = :review_skipped

    def index
      session[SKIPPED] = []
      @filters = filters
      @count = queue.count
      @by_source = queue.reorder(nil).group(:source).count.sort_by { |_source, count| -count }
      @by_venue = queue.reorder(nil).group("venues.id", "venues.name").count
                       .sort_by { |(_id, name), count| [-count, name.to_s] }.first(40)
      @first = queue.first
      @counts = WHO.index_with { |who| queue(@filters.merge(who: who)).count }
    end

    def show
      @gig = Lml::Gig.find(params[:id])
      @filters = filters
      @same_night = same_night(@gig)
      @remaining = queue.where.not(id: @gig.id).count
      @acts = suggested_acts(@gig)
      @genres = suggested_genres(@gig)
    end

    def update
      @gig = Lml::Gig.find(params[:id])
      @filters = filters

      case params[:decision]
      when "save"
        return redisplay unless confirm(@gig)

        notice = "Checked #{@gig.name}."
      when "hide"
        @gig.update!(hidden: true, checked: true)
        notice = "Hid #{@gig.name}."
      else
        skipped << @gig.id
        notice = "Skipped #{@gig.name}."
      end

      redirect_to next_after(@gig), notice: notice
    end

    private

    # Unchecked and not hidden, from today on, in the order a person would want
    # to work through them: a venue at a time, then by date, so the lineup
    # conventions of one room are fresh while they are being read.
    def queue(filters = @filters)
      gigs = Lml::Gig.joins(:venue)
                     .where(checked: [false, nil], hidden: [false, nil])
                     .where(date: Date.current..)
                     .order("venues.name", "gigs.date", "gigs.start_offset", "gigs.name", "gigs.id")
      gigs = gigs.where(uploaded_by: current_user) if filters[:who] == "mine"
      gigs = gigs.where(source: filters[:source]) if filters[:source]
      gigs = gigs.where(upload_id: filters[:upload_id]) if filters[:upload_id]
      gigs = gigs.where(venue_id: filters[:venue_id]) if filters[:venue_id]
      gigs = gigs.merge(Lml::Venue.in_locations([filters[:location]])) if filters[:location]
      gigs
    end

    # `who` is always present, so every link and redirect carries it and a
    # queue started on everyone's gigs stays on them.
    def filters
      chosen = params.permit(*FILTERS).to_h.symbolize_keys.compact_blank
      chosen[:who] = "mine" unless WHO.include?(chosen[:who])
      chosen
    end

    def skipped
      session[SKIPPED] ||= []
    end

    # The next gig at the same venue while it has any left, then whatever is
    # first - a venue at a time, as the queue is ordered.
    def next_after(gig)
      rest = queue.where.not(id: skipped + [gig.id])
      upcoming = rest.where(venue_id: gig.venue_id).first || rest.first
      upcoming ? backstage_review_path(upcoming, @filters) : backstage_reviews_path(@filters)
    end

    # The confirmed lineup where there is one, otherwise the suggestion, so a
    # gig somebody already fixed by hand is not offered a worse guess.
    def suggested_acts(gig)
      gig.sets.any? ? gig.set_list : (gig.proposed_acts || []).join("\n")
    end

    def suggested_genres(gig)
      gig.genre_tags.present? ? gig.genre_tag_list : (gig.proposed_genre_tags || []).join("\n")
    end

    # The name and genres go in with the gig; the sets are rows hanging off it,
    # so they are written once it has saved - the same order
    # GigsController#save_gig keeps.
    def confirm(gig)
      attrs = params.require(:gig).permit(:name, :set_list, :genre_tag_list)
      Lml::Gig.transaction do
        gig.name = attrs[:name]
        gig.genre_tag_list = attrs[:genre_tag_list].to_s
        gig.checked = true
        if gig.name.blank?
          gig.errors.add(:name, :blank)
          raise ActiveRecord::Rollback
        end
        raise ActiveRecord::Rollback unless gig.save

        gig.set_list = attrs[:set_list].to_s
        true
      end
    end

    # Everything else at the venue that night. A research upload sends a site's
    # gig even where LML already has another on that night under a different
    # name, because it may be a second gig - or a rename, in which case this is
    # where the copy shows up, a click from being hidden.
    def same_night(gig)
      return Lml::Gig.none if gig.venue_id.nil? || gig.date.nil?

      Lml::Gig.where(venue_id: gig.venue_id, date: gig.date).where.not(id: gig.id).order(:start_offset, :name)
    end

    def redisplay
      @same_night = same_night(@gig)
      @remaining = queue.where.not(id: @gig.id).count
      @acts = params.dig(:gig, :set_list).to_s
      @genres = params.dig(:gig, :genre_tag_list).to_s
      render :show, status: :unprocessable_entity
    end
  end
end
