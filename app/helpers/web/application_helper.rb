module Web::ApplicationHelper
  def page_title(separator = " – ")
    [content_for(:title), 'Live Music Locator'].compact.join(separator)
  end

  def nav_item_classes(is_active)
   base_styles = "py-4 px-2 text-gray-200"
    if is_active
      "#{base_styles} font-semibold"
    else
      "#{base_styles} font-normal transition duration-200 hover:text-gray-300"
    end
  end
end
