ActiveAdmin.register Lml::AdminUser, as: "AdminUser" do
  permit_params do
    permitted = %i[email time_zone password password_confirmation]
    if params[:admin_user] && params[:admin_user][:password].blank? && params[:admin_user][:password_confirmation].blank?
      params[:admin_user].delete(:password)
      params[:admin_user].delete(:password_confirmation)
    end
    permitted
  end

  index do
    selectable_column
    column :email do |admin_user|
      link_to(admin_user.email, admin_admin_user_path(admin_user))
    end
    column :time_zone
    column :last_active_at do |resource|
      admin_time(resource.last_active_at)
    end
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
      row :email
      row :time_zone
      row :last_active_at do |resource|
        admin_time(resource.last_active_at)
      end
      row :created_at do |resource|
        admin_time(resource.created_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end

    panel "Assigned Venues" do
      if resource.venues.any?
        form action: unassign_venues_admin_admin_user_path(resource), method: :post do
          input name: :authenticity_token, type: :hidden, value: form_authenticity_token
          table_for resource.venues do
            column "" do |venue|
              input type: :checkbox, name: "venue_ids[]", value: venue.id
            end
            column :name do |venue|
              link_to venue.name, admin_venue_path(venue)
            end
            column :location
            column :time_zone
          end
          div style: "margin-top: 10px" do
            input type: :submit, value: "Unassign Selected",
                  class: "button",
                  data: { confirm: "Are you sure you want to unassign these venues?" }
          end
        end
      else
        "No assigned venues found."
      end
    end

    div style: "height: 20px"

    panel "Available Venues (Not Assigned)" do
      available_venues = Lml::Venue.where(admin_user_id: nil).limit(50)
      if available_venues.any?
        form action: assign_venues_admin_admin_user_path(resource), method: :post do
          input name: :authenticity_token, type: :hidden, value: form_authenticity_token
          table_for available_venues do
            column "" do |venue|
              input type: :checkbox, name: "venue_ids[]", value: venue.id
            end
            column :name do |venue|
              link_to venue.name, admin_venue_path(venue)
            end
            column :location
            column :time_zone
          end
          div style: "margin-top: 10px" do
            input type: :submit, value: "Assign Selected",
                  class: "button"
          end
        end
      else
        "No available venues found."
      end
    end
  end

  member_action :unassign_venues, method: :post do
    venue_ids = params[:venue_ids]
    if venue_ids.present?
      count = resource.venues.where(id: venue_ids).update_all(admin_user_id: nil)
      flash[:notice] = "#{count} venue(s) unassigned."
    else
      flash[:error] = "No venues selected."
    end
    redirect_to admin_admin_user_path(resource)
  end

  member_action :assign_venues, method: :post do
    venue_ids = params[:venue_ids]
    if venue_ids.present?
      count = Lml::Venue.where(id: venue_ids, admin_user_id: nil).update_all(admin_user_id: resource.id)
      flash[:notice] = "#{count} venue(s) assigned."
    else
      flash[:error] = "No venues selected."
    end
    redirect_to admin_admin_user_path(resource)
  end


  filter :email_cont, label: "Email"
  filter :time_zone_cont, label: "Timezone"
  filter :last_active_at
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :email
      f.input(
        :time_zone,
        as: :select,
        collection: Lml::Timezone::CANONICAL_TIMEZONES,
      )
      f.input :password, required: params[:id].nil?
      f.input :password_confirmation
    end
    f.actions
  end
end
