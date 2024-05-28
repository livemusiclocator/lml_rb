ActiveAdmin.register Lml::Gig, as: "Gig" do
  permit_params(
    :date,
    :description,
    :headline_act_id,
    :hidden,
    :name,
    :start_offset_time,
    :status,
    :tag_list,
    :ticketing_url,
    :venue_id,
    :source,
    :set_list,
    :price_list,
  )

  filter :name_cont, label: "Name"
  filter :venue_location_cont, label: "Location"
  filter :date
  filter :tags, as: :check_boxes, collection: proc {Lml::Gig.visible.map{|gig| gig.tags.grep(/genre/)}.flatten.uniq},label: "Genre tags"

  filter :source_cont, label: "Source"
  filter :status, as: :select, collection: Lml::Gig.statuses.keys
  filter :checked
  filter :created_at
  filter :updated_at



  index do
    selectable_column
    column :name do |gig|
      link_to(gig.name, admin_gig_path(gig))
    end
    column :venue
    column :date do |resource|
      admin_date(resource.date)
    end
    column :start_offset_time
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
      row :status
      row :source
      row :duration
      row :finish_time do |resource|
        admin_time(resource.finish_time)
      end
      row :description do |gig|
        pre { gig.description }
      end
      row :tickets do |gig|
        link_to("tickets", gig.ticketing_url, target: "_blank", rel: "noopener noreferrer") if gig.ticketing_url
      end
      row :tag_list
      row :headline_act
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

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :date, as: :date_picker
      f.input :start_offset_time, as: :time_picker, label: "Start Time"
      f.input :duration, label: "Duration (mins)"
      f.input :ticketing_url
      f.input :status, as: :select, collection: Lml::Gig.statuses.keys
      f.input :source
      f.input :hidden
      f.input :headline_act_label, label: "Headline Act"
      f.input :headline_act_id, as: "hidden"
      f.input :description, input_html: { rows: 5 }
    end
    f.inputs "Tags" do
      f.input :tag_list
      para(
        "Separate tags with commas (eg. genre:Punk, information:18+, category:Band, series: LBMF2024)",
        style: "font-size: small",
      )
    end
    f.inputs "Sets" do
      f.input :set_list, as: :text, input_html: { rows: 5 }
      para(
        "One set per line, enter act name, start time and duration separated by pipes (eg. The Beatles|19:00|60)",
        style: "font-size: small",
      )
    end
    f.inputs "Prices" do
      f.input :price_list, as: :text, input_html: { rows: 5 }
      para(
        "One price per line, enter amount and description separated by pipes (eg. 10.00|Concession)",
        style: "font-size: small",
      )
    end
    script <<~SCRIPT.html_safe
      attachAutocomplete("lml_gig_venue", "/venues/autocomplete", "Select Venue");
      attachAutocomplete("lml_gig_headline_act", "/acts/autocomplete", "Select Headline Act");
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
