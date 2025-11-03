ActiveAdmin.register Lml::Act, as: "Act" do
  permit_params(
    :bandcamp,
    :country,
    :facebook,
    :genre_list,
    :instagram,
    :location,
    :musicbrainz,
    :name,
    :rym,
  )

  filter :name_cont, label: "Name"
  filter :country_cont, label: "Country"
  filter :location_cont, label: "Location"

  index do
    selectable_column
    column :name do |act|
      link_to(act.name, admin_act_path(act))
    end
    column :country
    column :location
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
      row :country
      row :location
      row :instagram do
        link_to("@#{resource.instagram}", "https://instagram.com/#{resource.instagram}") if resource.instagram.present?
      end
      row :facebook do
        link_to("@#{resource.facebook}", "https://facebook.com/#{resource.facebook}") if resource.facebook.present?
      end
      row :bandcamp do
        link_to("@#{resource.bandcamp}", "https://#{resource.bandcamp}.bandcamp.com") if resource.bandcamp.present?
      end
      row :musicbrainz do
        if resource.musicbrainz.present?
          link_to("@#{resource.musicbrainz}", "https://musicbrainz.org/artist/#{resource.musicbrainz}")
        end
      end
      row :rym do
        link_to("@#{resource.rym}", "https://rateyourmusic.com/artist/#{resource.rym}") if resource.rym.present?
      end

      row :genre_list
      row :created_at do |resource|
        admin_time(resource.updated_at)
      end
      row :updated_at do |resource|
        admin_time(resource.updated_at)
      end
    end
  end

  sidebar "Links", only: :show do
    ul do
      li link_to "Sets", admin_sets_path("q[act_id_eq]" => resource.id)
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :country, as: "string"
      f.input :instagram
      f.input :facebook
      f.input :bandcamp
      f.input :musicbrainz
      f.input :rym
      f.input :location
      f.input :genre_list
    end
    f.actions
  end
end
