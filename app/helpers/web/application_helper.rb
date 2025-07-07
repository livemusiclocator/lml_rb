# frozen_string_literal: true

module Web
  module ApplicationHelper
    STATIC_PAGES = [
      { name: "About (v2)", page_id: "about_lml" },
      { name: "The Team", page_id: "the-team" },
      { name: "Contact", page_id: "contact" },
      { name: "Privacy Policy", page_id: "privacy-policy" },
      { name: "Tech", page_id: "tech" },
      { name: "Volunteering", page_id: "volunteering" },
      { name: "DIY Gig Guide", page_id: "diy-gig-guide" },
      { name: "Fresh Live Music Data", page_id: "fresh-live-music-data" },
      { name: "API Documentation", page_id: "api-documentation" },
      { name: "How To Use Live Music Locator", page_id: "how-to-use-livemusiclocator" },
      { name: "API, Stats, and Data", page_id: "api-stats-and-data" },
    ].freeze

    TOP_NAV = {
      home: { name: "Home", path_name: :web_root },
      menu: [
        { name: "Home", path_name: :web_root },
        # TODO: better way to match /start/about to /start/about/a and /about/b  but not match /start/ to everything?
        { name: "About", path_name: :web_about_page, section_page: true },
        { name: "Events", path_name: :web_events },
      ],
    }.freeze

    def home_path
      relative_path(TOP_NAV[:home])
    end

    def nav_menu_items
      TOP_NAV[:menu].map do |menu_item|
        path = relative_path(menu_item)
        current = if menu_item[:section_page]
                    request.fullpath.start_with?(path)
                  else
                    current_page?(path)
                  end
        menu_item.merge({ path: path, current: current })
      end
    end

    def relative_path(path_info = {})
      path = path_info[:path_name]
      path_params = path_info[:params]
      extra_context = params[:edition_id] ? [:edition] : []
      extra_params = params[:edition_id] ? { edition_id: params[:edition_id] } : {}

      polymorphic_path([params[:home_path]] + extra_context + [path], extra_params.merge(path_params || {}))
    end

    def about_page_path(page_id)
      relative_path({ path_name: :web_about_section_page, params: { id: page_id } })
    end

    def about_section_static_pages
      pages = STATIC_PAGES.map do |page|
        path = about_page_path(page[:page_id])

        page.merge(path: path)
      end

      pages.unshift({ name: "About", path: web_about_page_path })

      pages
    end

    def nav_item_classes(is_active)
      base_styles = "text-slate-50"
      if is_active
        "#{base_styles} font-semibold"
      else
        "#{base_styles} font-normal transition duration-200 hover:text-slate-300"
      end
    end

    def team_members
      @team_members ||= YAML.load_file(Rails.root.join("config", "content", "team_members.yml"), symbolize_names: true)
    end
  end
end
