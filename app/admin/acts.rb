ActiveAdmin.register Lml::Act, as: "Act" do
  permit_params(
    :bandcamp,
    :country,
    :facebook,
    :genre_list,
    :instagram,
    :linktree,
    :location,
    :musicbrainz,
    :name,
    :rym,
    :website,
    :wikipedia,
    :youtube,
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

      row :website do
        link_to(resource.website, resource.website) if resource.website.present?
      end
      row :instagram do
        link_to(resource.instagram_url, resource.instagram_url) if resource.instagram.present?
      end
      row :facebook do
        link_to(resource.facebook_url, resource.facebook_url) if resource.facebook.present?
      end
      row :linktree do
        link_to(resource.linktree_url, resource.linktree_url) if resource.linktree.present?
      end
      row :bandcamp do
        link_to(resource.bandcamp_url, resource.bandcamp_url) if resource.bandcamp.present?
      end
      row :musicbrainz do
        link_to(resource.musicbrainz_url, resource.musicbrainz_url) if resource.musicbrainz.present?
      end
      row :rym do
        link_to(resource.rym_url, resource.rym_url) if resource.rym.present?
      end
      row :wikipedia do
        link_to(resource.wikipedia_url, resource.wikipedia_url) if resource.wikipedia.present?
      end
      row :youtube do
        link_to(resource.youtube_url, resource.youtube_url) if resource.youtube.present?
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
      f.input :location
      f.input :website
      f.input :instagram
      f.input :facebook
      f.input :linktree
      f.input :bandcamp
      f.input :musicbrainz
      f.input :rym
      f.input :wikipedia
      f.input :youtube
      f.input :genre_list
    end
    f.actions
  end
end
