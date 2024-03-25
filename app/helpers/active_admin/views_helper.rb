module ActiveAdmin::ViewsHelper
  def admin_time(time)
    return "-" if time.nil?

    time.iso8601.sub("T", " ")
  end

  def admin_date(date)
    return "-" if date.nil?

    date.iso8601
  end
end
