ActiveAdmin.register AdminUser do
  permit_params(
    :email,
    :password,
    :password_confirmation,
    :time_zone,
  )

  index do
    selectable_column
    column :email do |admin_user|
      link_to(admin_user.email, admin_admin_user_path(admin_user))
    end
    column :time_zone
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :time_zone
      row :created_at
      row :updated_at
    end
  end

  filter :email_cont, label: "Email"
  filter :time_zone_cont, label: "Timezone"
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :time_zone, as: :select, collection: ActiveSupport::TimeZone.country_zones("AU").map { |t| t.name }.sort
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
