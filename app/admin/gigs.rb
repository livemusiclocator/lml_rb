# frozen_string_literal: true

ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :category,
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

  filter :name_cont, label: "Name"
  filter :venue_location_cont, label: "Location"
  filter :venue, as: :select, collection: -> { Lml::Venue.order(:name).pluck(:name, :id) }
  filter :date
  filter :series_cont, label: "Series"
  filter :category_cont, label: "Category"
  filter :source_cont, label: "Source"
  filter :status, as: :select, collection: Lml::Gig.statuses.keys
  filter :checked

  index do
    selectable_column
    column :name do |gig|
      link_to(gig.name, admin_gig_path(gig))
    end
    column :venue
    column :date do |resource|
      admin_date(resource.date)
    end
    column :category
    column :series
    column :status
    column :source
    column :tag_list

    column :created_at do |resource|
      admin_time(resource.created_at)
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    actions
  end

  index as: ActiveAdmin::Views::CanvaCustomIndex do
    column :venue
    column :name
    column :start_time
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :venue
      row :date do |resource|
        admin_date(resource.date)
      end
      row :start_offset_time
      row :start_time do |resource|
        admin_time(resource.start_time)
      end
      row :start_at do |resource|
        admin_time(resource.start_at)
      end
      row :category
      row :series
      row :status
      row :ticket_status
      row :information_tag_list
      row :proposed_genre_tag_list
      row :genre_tag_list
      row :source
      row :duration
      row :finish_time do |resource|
        admin_time(resource.finish_time)
      end
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
        column :start_offset_time
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

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :date, as: :date_picker
      f.input :start_time, as: :time_picker
      f.input :duration, label: "Duration (mins)"
      f.input :url
      f.input :ticketing_url
      f.input :status, as: :select, collection: Lml::Gig.statuses.keys
      f.input :ticket_status, as: :select, collection: Lml::Gig.ticket_statuses.keys
      f.input :source
      f.input :hidden
      f.input :series
      f.input :category
      f.input :description, input_html: { rows: 5 }
      f.input :internal_description, input_html: { rows: 5 }
    end
    f.inputs "Genre Tags" do
      f.input :genre_tag_list, as: :text, input_html: { rows: 5 }
      content = if f.object.proposed_genre_tags
                  "One tag per line (proposed: #{f.object.proposed_genre_tags.join(", ")})"
                else
                  "One tag per line"
                end
      para(content, style: "font-size: small")
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
      para(
        "One set per line, enter act name, start time, duration and stage separated by pipes (eg. The Beatles | 19:00 | 60 | main stage)",
        style: "font-size: small",
      )
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

  controller do
    def create
      super
      resource.update!(start_time: resource.start_at)
    end

    def update
      super
      resource.update!(start_time: resource.start_at)
    end
  end
end
