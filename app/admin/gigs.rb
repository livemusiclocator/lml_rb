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
    prices_attributes: [:id, :amount, :description],
    sets_attributes: [:act_id, :start_offset_time, :duration]
  )

  filter :name_cont, label: "Name"
  filter :venue_location_cont, label: "Location"
  filter :date
  filter :status, as: :select, collection: Lml::Gig.statuses.keys
  filter :checked
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :name do |gig|
      link_to(gig.name, admin_gig_path(gig))
    end
    column :status
    column :start_offset_time
    column :tickets do |gig|
      link_to("link", gig.ticketing_url, target: "_blank", rel: "noopener noreferrer") if gig.ticketing_url
    end
    column :date do |resource|
      admin_date(resource.date)
    end
    column :venue
    column :headline_act
    column :created_at do |resource|
      admin_time(resource.created_at)
    end
    column :updated_at do |resource|
      admin_time(resource.updated_at)
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :status
      row :date do |resource|
        admin_date(resource.date)
      end
      row :start_offset_time
      row :start_at do |resource|
        admin_time(resource.start_at)
      end
      row :duration
      row :start_time do |resource|
        admin_time(resource.start_time)
      end
      row :finish_time do |resource|
        admin_time(resource.finish_time)
      end
      row :description do |gig|
        pre { gig.description }
      end
      row :venue
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
    f.inputs do
      f.input :name
      f.input :venue_label, label: "Venue"
      f.input :venue_id, as: "hidden"
      f.input :headline_act_label, label: "Headline Act"
      f.input :headline_act_id, as: "hidden"
      f.input :date, as: :date_picker
      f.input :start_offset_time, as: :time_picker, label: "Start Time"
      f.input :hidden
      f.input :duration, label: "Duration (mins)"
      f.input :ticketing_url
      f.input :tag_list, as: "text"
      f.input :status, as: :select, collection: Lml::Gig.statuses.keys
      f.input :description
      f.inputs 'Prices' do
        f.has_many :prices,
                 heading: false,
                 new_record: 'Add Ticket Price',
                 remove_record: 'Remove Ticket Price' do |b|
                  b.input :amount
                  b.input :description
        end
      end
      f.inputs "Set List" do
        f.has_many :sets  do |s|
          s.input :act_label, label: "Act"
          s.input :act_id, as: "hidden"
          s.input :start_offset_time, as: :time_picker, label: "Start Time"
          s.input :duration, label: "Duration (mins)"
          script <<~SCRIPT.html_safe
            attachAutocomplete(`lml_gig_sets_attributes_#{s.index}_act`, "/acts/autocomplete", "Select Act");
          SCRIPT
        end
      end
    end
    script <<~SCRIPT.html_safe
      attachAutocompleteForNewHasMany('lml_gig_sets_attributes_INDEX_act', "/acts/autocomplete", "Select Act");
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
