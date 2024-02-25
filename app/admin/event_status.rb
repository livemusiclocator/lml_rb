ActiveAdmin.register EventStatus do
  permit_params :name

  filter :none

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end
end
