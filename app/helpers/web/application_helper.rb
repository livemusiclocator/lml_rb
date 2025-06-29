module Web::ApplicationHelper
  def page_title(separator = " – ")
    [content_for(:title), 'Live Music Locator'].compact.join(separator)
  end
end
