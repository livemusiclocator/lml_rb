ActiveAdmin.register Lml::Price, as: "Price" do
  permit_params(
    :gig_id,
    :amount,
    :description,
  )

  filter :none

  index do
    selectable_column
    column :gig
    column :amount
  end

  show do
    attributes_table do
      row :id
      row :gig
      row :amount
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :gig_label, label: "Gig"
      f.input :gig_id, as: "hidden"
      f.input :description
      f.input :amount
    end
    script <<~SCRIPT.html_safe
      attachAutocomplete("lml_set_gig", "/gigs/autocomplete", "Select Gig");
      attachAutocomplete("lml_set_act", "/acts/autocomplete", "Select Act");
    SCRIPT
    f.actions
  end

  controller do
    def new
      gig_id = params[:gig_id]

      @price = Lml::Price.new(
        gig_id: gig_id,
      )
    end
  end
end
