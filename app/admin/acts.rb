ActiveAdmin.register Lml::Act, as: "Act" do
  permit_params(
    :bandcamp,
    :country,
    :email,
    :facebook,
    :genre_list,
    :instagram,
    :linktree,
    :location,
    :musicbrainz,
    :name,
    :rym,
    :spotify,
    :website,
    :wikipedia,
    :youtube,
    :alias_list,
  )

  # Same shape as app/admin/venues.rb, and for the same reason: ActiveAdmin reports what it was
  # asked to do rather than what happened, so Lml::Act's `dependent: :restrict_with_error` needs
  # both delete paths rewritten or they claim a deletion that did not occur.
  controller do
    def destroy
      if destroy_resource(resource)
        redirect_to admin_acts_path, notice: "Act was successfully destroyed."
      else
        redirect_to admin_act_path(resource), alert: sets_blocking_delete(resource)
      end
    end

    # Also reached from the batch action, which runs in this controller.
    def sets_blocking_delete(act)
      count = act.sets.count

      "#{act.name} is still on the bill for #{count} #{"gig".pluralize(count)}, so it was not " \
        "deleted. Take it off those line ups first."
    end
  end

  batch_action :destroy, confirm: I18n.t("active_admin.delete_confirmation") do |ids|
    deleted, blocked = Lml::Act.where(id: ids).partition(&:destroy)

    messages = []
    messages << "Deleted #{deleted.size} #{"act".pluralize(deleted.size)}." if deleted.any?
    messages += blocked.map { |act| sets_blocking_delete(act) }

    if blocked.any?
      redirect_to collection_path, alert: messages.join(" ")
    else
      redirect_to collection_path, notice: messages.join(" ")
    end
  end

  filter :name_cont, label: "Name"
  filter :country_cont, label: "Country"
  filter :location_cont, label: "Location"

  index do
    selectable_column
    column :name do |act|
      label = act.name
      label += " - (#{act.aliases.join(", ")})" if act.aliases.present?
      link_to(label, admin_act_path(act))
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
      row :email

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
      row :spotify do
        link_to(resource.spotify_url, resource.spotify_url) if resource.spotify.present?
      end
      row :wikipedia do
        link_to(resource.wikipedia_url, resource.wikipedia_url) if resource.wikipedia.present?
      end
      row :youtube do
        link_to(resource.youtube_url, resource.youtube_url) if resource.youtube.present?
      end

      row :genre_list
      row :alias_list
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
      f.input :email
      f.input :website
      f.input :instagram
      f.input :facebook
      f.input :linktree
      f.input :bandcamp
      f.input :musicbrainz
      f.input :rym
      f.input :spotify
      f.input :wikipedia
      f.input :youtube
      f.input :genre_list
      f.input :alias_list
    end
    f.actions
  end
end
