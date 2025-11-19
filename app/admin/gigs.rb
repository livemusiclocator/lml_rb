# frozen_string_literal: true

module ActiveAdmin
  module Views
    class IndexAsGigSchedule < ActiveAdmin::Component
      def build(_page_presenter, collection)
        @gig_schedule_presenter = GigSchedulePresenter.new(collection, params)

        render "admin/gigs/gigs_schedule",
               { gig_schedule_presenter: GigSchedulePresenter.new(collection, params) }
        # render "admin/gigs/gig_schedule_view"
      end

      def self.index_name
        "schedule"
      end
    end
  end
end
ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :category,
    :checked,
    :date,
    :description,
    :genre_tag_list,
    :hidden,
    :information_tag_list,
    :internal_description,
    :name,
    :price_list,
    :series,
    :set_list,
    :source,
    :start_time,
    :status,
    :ticket_status,
    :ticketing_url,
    :url,
    :venue_id,
  )

  config.per_page = [50, 100, 200]
  config.sort_order = "date_asc" # defaulting to beginning of the week date filter, this makes sense

  filter :name_cont, label: "Name", if: proc { params[:scope] != "potential_duplicates" }
  filter :venue_location_cont, as: :select, label: "Location", collection: -> { Web::Location.order(:name).pluck(:name, :internal_identifier) }

  filter :venue, as: :select, collection: -> { Lml::Venue.order(:name).pluck(:name, :id) }
  filter :date
  filter :start_time_offset, if: proc { params[:scope] != "potential_duplicates" }
  filter :start_time_offset_null, if: proc { params[:scope] != "potential_duplicates" }
  filter :series_cont, label: "Series", if: proc { params[:scope] != "potential_duplicates" }
  filter :category_cont, label: "Category", if: proc { params[:scope] != "potential_duplicates" }
  filter :source_cont, label: "Source", if: proc { params[:scope] != "potential_duplicates" }
  filter :status, as: :select, collection: Lml::Gig.statuses.keys, if: proc { params[:scope] != "potential_duplicates" }
  filter :checked, if: proc { params[:scope] != "potential_duplicates" }
  filter :hidden, if: proc { params[:scope] != "potential_duplicates" }

  scope "All gigs", :eager, default: true, show_count: false

  scope "Potential duplicates", :potential_duplicates, show_count: false, group: :reports do
    search = Lml::Gig.visible.potential_duplicates.ransack(params[:q])
    search.sorts = %w[venue_name date start_offset] if search.sorts.empty?
    search.result.includes(:venue)
  end
  scope :this_week

  before_action only: :index do
    if params[:commit].blank?
      params[:q] ||= {}
      # defaulting the gig list to things happening this week and onward
      params[:q][:date_gteq] = Date.today.beginning_of_week
    end
    if params[:as].blank?
      params[:as] = case params[:scope]
                    when "potential_duplicates", "this_week"
                      "schedule"
                    else
                      "table"
                    end

    end
    if params[:as] == "schedule"
      # remove the user-defined sort here as it does not really make sense when showing the schedule
      # (maybe if the sort was by week-start or venue perhaps?)
      params["order"] = nil
    end
  end

  index do
    selectable_column
    column :name do |gig|
      link_to(gig.name, admin_gig_path(gig))
    end
    column :venue
    column :date do |resource|
      admin_date(resource.date)
    end
    column :start_time
    column :checked
    column :hidden
    column :category
    column :series
    column :status
    column :source
    column :genre_tag_count do |resource|
      (resource.published_genre_tags || []).count
    end

    column :created_at do |resource|
      admin_time(resource.created_at)
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    actions
  end

  index as: :gig_schedule

  index as: ActiveAdmin::Views::CanvaCustomIndex do
    column :venue
    column :name
    column :start_time
    actions
  end
  # rubocop:disable Metrics/BlockLength
  show do
    attributes_table do
      row :id
      row :name
      row :venue
      row :date do |resource|
        admin_date(resource.date)
      end
      row :start_time
      row :start_timestamp do |resource|
        admin_time(resource.start_timestamp)
      end
      row :duration
      row :finish_time
      row :finish_timestamp do |resource|
        admin_time(resource.finish_timestamp)
      end
      row :checked
      row :hidden
      row :category
      row :series
      row :status
      row :ticket_status
      row :information_tag_list
      row :proposed_genre_tag_list
      row :genre_tag_list
      row :source
      row :url do |gig|
        link_to("url", gig.url, target: "_blank", rel: "noopener noreferrer") if gig.url
      end
      row :description do |gig|
        pre { gig.description }
      end
      row :internal_description do |gig|
        pre { gig.internal_description }
      end
      row :tickets do |gig|
        link_to("tickets", gig.ticketing_url, target: "_blank", rel: "noopener noreferrer") if gig.ticketing_url
      end
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end

    panel "Sets" do
      table_for gig.sets do
        column :link do |set|
          link_to "link", admin_set_path(set)
        end
        column :act
        column :start_time
        column :duration
        column :stage
      end
    end

    panel "Prices" do
      table_for gig.prices do
        column :link do |price|
          link_to "link", admin_price_path(price)
        end
        column :description
        column :amount
      end
    end
  end

  action_item :add_set, only: %i[show] do
    link_to(
      "Add Set",
      new_admin_set_path(
        gig_id: gig.id,
        start_offset: gig.start_offset,
      ),
      method: :get,
    )
  end

  action_item :add_price, only: %i[show] do
    link_to(
      "Add Price",
      new_admin_price_path(
        gig_id: gig.id,
      ),
      method: :get,
    )
  end

  batch_action :suggest_tags do |ids|
    batch_action_collection.find(ids).each do |gig|
      gig.suggest_tags!(force: true)
    end

    redirect_to collection_path, notice: "Added tags"
  end

  action_item :suggest_tags, only: %i[show] do
    link_to "Suggest tags", suggest_tags_admin_gig_path(resource), method: :put
  end

  member_action :suggest_tags, method: :put do
    resource.suggest_tags!(force: true)
    redirect_to resource_path, notice: "Added tags"
  end

  action_item :clone, only: %i[show] do
    link_to "Clone", clone_admin_gig_path(resource), method: :put
  end

  member_action :clone, method: :put do
    new_gig = Lml::Gig.new
    new_gig.attributes = resource.attributes.except("id", "created_at", "updated_at", "upload_id")
    new_gig.date = new_gig.date + 7.days
    new_gig.price_list = resource.price_list
    new_gig.set_list = resource.set_list
    new_gig.save!
    redirect_to edit_admin_gig_path(new_gig)
  end

  action_item :download_gigs, only: [:index] do
    action_params = { format: :txt }
    action_params.merge!({ order: params[:order] }) if params[:order]
    action_params.merge!({ q: params[:q].permit! }) if params[:q]
    link_to(
      "Download Gigs",
      download_gigs_admin_gigs_path(action_params),
    )
  end

  collection_action :download_gigs, method: :get do
    larger_collection = collection.offset(nil).limit(500)
    send_data(
      Lml::Processors::ClipperSerialiser.for_collection(larger_collection),
      type: "application/txt",
      filename: "gigs_#{Time.now.iso8601}.txt",
    )
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :date, as: :date_picker
      f.input :start_time, as: :time_picker
      f.input :finish_time, as: :time_picker
      f.input :checked
      f.input :ticketing_url
      if f.object.ticketing_url.present?
        li do
          link_to("(current ticketing url)", f.object.ticketing_url, target: "_blank", rel: "noopener noreferrer")
        end
      end
      f.input :status, as: :select, collection: Lml::Gig.statuses.keys
      f.input :ticket_status, as: :select, collection: Lml::Gig.ticket_statuses.keys
      f.input :hidden
      f.input :internal_description, input_html: { rows: 5 }
    end
    f.inputs "Genre Tags" do
      f.input :genre_tag_list, as: :text, input_html: { rows: 5 }
      para("One tag per line", style: "font-size: small")
      proposed = f.object.proposed_genre_tags || []
      if proposed.any?
        para("Proposed genre tags:", style: "font-size: small")
        pre(proposed.join("\n"), style: "font-size: small")
      end
    end
    f.inputs "Information Tags" do
      f.input :information_tag_list, as: :text, input_html: { rows: 5 }
      para(
        "One tag per line",
        style: "font-size: small",
      )
    end

    f.inputs "Sets" do
      f.input :set_list, as: :text, input_html: { rows: 5 }
      help_text = <<-TEXT
          One set per line, enter act name, start time, finish time and stage separated by pipes
          (eg. The Beatles | 7:30pm | 8:30pm | main stage)
      TEXT
      para(help_text, style: "font-size: small")
    end
    f.inputs "Prices" do
      f.input :price_list, as: :text, input_html: { rows: 5 }
      para(
        "One price per line, enter amount and description separated by pipes (eg. 10.00 | Concession)",
        style: "font-size: small",
      )
    end
    script <<~SCRIPT.html_safe
      attachAutocomplete("lml_gig_venue", "/venues/autocomplete", "Select Venue");
    SCRIPT
    f.actions
  end
  # rubocop:enable Metrics/BlockLength
  controller do
    def create
      # finish time needs to be assigned after start time
      finish_time = params[:lml_gig].delete(:finish_time)

      super

      resource.update!(finish_time: finish_time) if resource.valid? && !finish_time.blank?
    end

    def update
      # finish time needs to be assigned after start time
      finish_time = params[:lml_gig].delete(:finish_time)

      super

      resource.update!(finish_time: finish_time) if resource.valid? && !finish_time.blank?
    end

    def index
      super do |format|
        format.json do
          render json: collection.as_json(
            include: :prices,
          )
        end
      end
    end
  end
end
