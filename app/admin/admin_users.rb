ActiveAdmin.register AdminUser do
  permit_params do
    permitted = %i[email time_zone password password_confirmation]
    if params[:admin_user][:password].blank? && params[:admin_user][:password_confirmation].blank?
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
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end
  end

  filter :email_cont, label: "Email"
  filter :time_zone_cont, label: "Timezone"
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
