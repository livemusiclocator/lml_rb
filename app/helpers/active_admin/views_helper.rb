module ActiveAdmin::ViewsHelper
  def admin_time(time)
    return "-" if time.nil?

    time.strftime("%a %d %b %y %R %z")
  end

  def admin_date(date)
    return "-" if date.nil?

    date.strftime("%a %d %b %y")
  end

  # Renders a hash as indented json for reading rather than editing. `pre` keeps the indentation,
  # and wrapping stops a long value from widening the whole page.
  def pretty_json(data)
    return "-" if data.blank?

    content_tag(
      :pre,
      JSON.pretty_generate(data),
      style: "margin: 0; white-space: pre-wrap; word-break: break-word;",
    )
  end
end
