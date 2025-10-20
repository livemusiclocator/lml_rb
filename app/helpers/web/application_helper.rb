# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Web
  module ApplicationHelper
    STATIC_PAGES = { base: { about: {
      pages: [
        { name: "About", page_id: "about", content_page_id: "about", section_root_page: true },
        { name: "The Team", page_id: "the-team", content_page_id: "the-team" },
        { name: "Volunteering", page_id: "volunteering", content_page_id: "volunteering" },
        { name: "How To Use", page_id: "how-to-use-livemusiclocator", content_page_id: "how-to-use-livemusiclocator" },
        { name: "API, Stats, and Data", page_id: "api-stats-and-data", content_page_id: "api-stats-and-data" },
        { name: "Contact", page_id: "contact", content_page_id: "contact" },
        { name: "Privacy Policy", page_id: "privacy-policy", content_page_id: "privacy_policy" },
      ],
    } }, stkilda: { about: {
      pages: [
        { name: "About", page_id: "about", content_page_id: "st-kilda-live-music", section_root_page: true },
        { name: "The Team", page_id: "the-team", content_page_id: "the-team" },
        { name: "Volunteering", page_id: "volunteering", content_page_id: "volunteering" },
        { name: "How To Use", page_id: "how-to-use-livemusiclocator", content_page_id: "how-to-use-livemusiclocator" },
        { name: "API, Stats, and Data", page_id: "api-stats-and-data", content_page_id: "api-stats-and-data" },
        { name: "Contact", page_id: "contact", content_page_id: "contact" },
        { name: "Privacy Policy", page_id: "privacy-policy", content_page_id: "privacy_policy" },
      ],
    } }, geelong: { about: {
      pages: [
        { name: "About", page_id: "about", content_page_id: "about-geelong", section_root_page: true },
        { name: "The Team", page_id: "the-team", content_page_id: "the-team" },
        { name: "Volunteering", page_id: "volunteering", content_page_id: "volunteering" },
        { name: "How To Use", page_id: "how-to-use-livemusiclocator",
          content_page_id: "how-to-use-livemusiclocator", },
        { name: "API, Stats, and Data", page_id: "api-stats-and-data", content_page_id: "api-stats-and-data" },
        { name: "Contact", page_id: "contact", content_page_id: "contact" },
        { name: "Privacy Policy", page_id: "privacy-policy", content_page_id: "privacy_policy" },
      ],
    } }, }.freeze

    TOP_NAV = {
      home: { name: "Home", path_name: :web_root },
      menu: [
        { name: "Home", path_name: :web_root },
        { name: "About", path_name: :web_about_page, section_page: true },
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

    def about_section_nav
      key = params[:edition_id]&.to_sym || :base
      about_section = STATIC_PAGES.dig(key, :about) || {}
      (about_section[:pages] || []).map do |page|
        path = if page[:section_root_page]
                 relative_path({ path_name: :web_about_page })
               else
                 about_page_path(page[:page_id])
               end
        page.merge(path: path)
      end
    end

    def about_section_static_page(edition, page_id)
      edition_key = edition&.to_sym || :base
      pages = STATIC_PAGES.dig(edition_key, :about, :pages) || []
      pages.detect { |page| page[:page_id] == page_id }
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

    # sets the heading text to be different from the title
    def override_page_heading(heading_text)
      @override_page_heading ||= heading_text
    end

    def page_heading
      @heading_text || title
    end

    # TODO: merge with all the other millions of places we have editon config etc.
    EDITION_PARAMS = {
      "stkilda" => {
        edition_title: "St Kilda",
      },
      "geelong" => {
        edition_title: "Geelong",
      },
    }.freeze

    def site_title
      "Live Music Locator"
    end

    def edition_title
      edition_params = EDITION_PARAMS[params[:edition_id]]

      edition_params ? edition_params[:edition_title] : ""
    end
  end
end
# rubocop:enable Metrics/ModuleLength
