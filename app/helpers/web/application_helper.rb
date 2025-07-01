module Web::ApplicationHelper
  def page_title(separator = " – ")
    [content_for(:title), 'Live Music Locator'].compact.join(separator)
  end
  STATIC_PAGES = [
    { name: 'About (v2)', page_id: 'about_lml' },
    { name: 'The Team', page_id: 'the-team' },
    { name: 'Contact', page_id: 'contact' }

  ].freeze

  def about_section_static_pages
    pages = STATIC_PAGES.map do |page|
      path = web_about_section_page_path(page[:page_id])

      page.merge(path: path)
    end

    pages.unshift({name: "About", path: web_about_page_path})

    return pages
  end

  def nav_item_classes(is_active)
   base_styles = "text-slate-50"
    if is_active
      "#{base_styles} font-semibold"
    else
      "#{base_styles} font-normal transition duration-200 text-slate-300"
    end
  end
  def team_members
    @team_members ||= YAML.load_file(Rails.root.join('config','content', 'team_members.yml'),symbolize_names:true)
  end
end
