# frozen_string_literal: true

ActiveAdmin.register Lml::User, as: "User" do
  menu label: "Backstage Users", priority: 3

  actions :all, except: [:new, :create, :edit, :update]

  permit_params :email, :display_name

  filter :email
  filter :display_name
  filter :admin
  filter :created_at

  index do
    selectable_column
    column :email
    column :display_name
    column :admin do |u|
      status_tag(u.admin? ? "admin" : "—", class: u.admin? ? :ok : nil)
    end
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
      row :admin do |u|
        status_tag(u.admin? ? "admin" : "not an admin", class: u.admin? ? :ok : nil)
      end
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

  # Admin is granted and revoked one user at a time and never through permit_params,
  # so nothing that mass assigns a user's attributes can quietly promote anybody.
  member_action :grant_admin, method: :post do
    resource.update!(admin: true)
    redirect_to admin_user_path(resource), notice: "#{resource.email} is now an admin."
  end

  member_action :revoke_admin, method: :delete do
    resource.update!(admin: false)
    # Losing admin has to take the API keys with it, or a demoted admin keeps
    # writing through a token nobody remembers issuing.
    resource.api_tokens.active.find_each(&:revoke!)
    redirect_to admin_user_path(resource), notice: "#{resource.email} is no longer an admin."
  end

  action_item :admin_access, only: :show do
    if resource.admin?
      link_to "Revoke admin", revoke_admin_admin_user_path(resource),
              method: :delete,
              data: { confirm: "Revoke admin access and all API tokens for #{resource.email}?" }
    else
      link_to "Grant admin", grant_admin_admin_user_path(resource),
              method: :post,
              data: { confirm: "Grant #{resource.email} full admin access?" }
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
    form action: add_venue_manager_admin_user_path(resource), method: :post do
      text_node hidden_field_tag(:authenticity_token, form_authenticity_token)
      text_node hidden_field_tag("venue_id", nil, id: "grant_venue_id")
      div style: "position: relative;" do
        text_node text_field_tag("venue_label", nil, id: "grant_venue_label", placeholder: "Search venues...", autocomplete: "off")
        div id: "grant_venue_results",
            style: "display: none; position: absolute; top: 100%; left: 0; right: 0; z-index: 10; " \
                    "background: #fff; border: 1px solid #ccc; max-height: 200px; overflow-y: auto;"
      end
      br
      input type: :submit, value: "Grant venue access"
    end
    br
    h4 "Add act access"
    form action: add_act_manager_admin_user_path(resource), method: :post do
      text_node hidden_field_tag(:authenticity_token, form_authenticity_token)
      text_node hidden_field_tag("act_id", nil, id: "grant_act_id")
      div style: "position: relative;" do
        text_node text_field_tag("act_label", nil, id: "grant_act_label", placeholder: "Search acts...", autocomplete: "off")
        div id: "grant_act_results",
            style: "display: none; position: absolute; top: 100%; left: 0; right: 0; z-index: 10; " \
                    "background: #fff; border: 1px solid #ccc; max-height: 200px; overflow-y: auto;"
      end
      br
      input type: :submit, value: "Grant act access"
    end
    script <<~SCRIPT.html_safe
      attachSearchAutocomplete("grant_venue", "/venues/search", "Search venues...");
      attachSearchAutocomplete("grant_act", "/acts/search", "Search acts...");
    SCRIPT
  end
end
