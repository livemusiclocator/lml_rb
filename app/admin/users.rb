# frozen_string_literal: true

ActiveAdmin.register Lml::User, as: "User" do
  menu label: "Backstage Users", priority: 3

  actions :all, except: [:new, :create, :edit, :update]

  permit_params :email, :display_name

  filter :email
  filter :display_name
  filter :created_at

  index do
    selectable_column
    column :email
    column :display_name
    column :managed_venues do |u|
      u.managed_venues.map(&:name).join(", ").presence || "—"
    end
    column :managed_acts do |u|
      u.managed_acts.map(&:name).join(", ").presence || "—"
    end
    column :proposals_count do |u|
      u.proposals.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :email
      row :display_name
      row :managed_venues do |u|
        u.managed_venues.map(&:label).join(", ").presence || "None"
      end
      row :managed_acts do |u|
        u.managed_acts.map(&:label).join(", ").presence || "None"
      end
      row :created_at
    end

    panel "Proposals" do
      table_for resource.proposals.order(created_at: :desc).limit(20) do
        column :target do |p|
          link_to p.target_label, admin_proposal_path(p)
        end
        column :status do |p|
          status_tag p.status
        end
        column :created_at
      end
    end
  end

  member_action :add_venue_manager, method: :post do
    venue = Lml::Venue.find(params[:venue_id])
    resource.venue_managers.find_or_create_by!(venue: venue)
    redirect_to admin_user_path(resource), notice: "#{resource.email} can now manage #{venue.name}."
  end

  member_action :add_act_manager, method: :post do
    act = Lml::Act.find(params[:act_id])
    resource.act_managers.find_or_create_by!(act: act)
    redirect_to admin_user_path(resource), notice: "#{resource.email} can now manage #{act.name}."
  end

  member_action :remove_venue_manager, method: :delete do
    venue = Lml::Venue.find(params[:venue_id])
    resource.venue_managers.where(venue: venue).destroy_all
    redirect_to admin_user_path(resource), notice: "Removed venue manager access."
  end

  member_action :remove_act_manager, method: :delete do
    act = Lml::Act.find(params[:act_id])
    resource.act_managers.where(act: act).destroy_all
    redirect_to admin_user_path(resource), notice: "Removed act manager access."
  end

  sidebar "Promote to manager", only: :show do
    h4 "Add venue access"
    form action: add_venue_manager_admin_user_path(resource), method: :post do |f|
      f.input :authenticity_token, type: :hidden, value: form_authenticity_token
      select_tag :venue_id, options_from_collection_for_select(Lml::Venue.order(:name), :id, :label),
                 include_blank: "Select venue..."
      br
      br
      input type: :submit, value: "Grant venue access"
    end
    br
    h4 "Add act access"
    form action: add_act_manager_admin_user_path(resource), method: :post do |f|
      f.input :authenticity_token, type: :hidden, value: form_authenticity_token
      select_tag :act_id, options_from_collection_for_select(Lml::Act.order(:name), :id, :name),
                 include_blank: "Select act..."
      br
      br
      input type: :submit, value: "Grant act access"
    end
  end
end
