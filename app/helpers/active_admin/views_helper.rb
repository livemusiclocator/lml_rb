module ActiveAdmin::ViewsHelper
  def admin_time(time)
    return "-" if time.nil?

    time.strftime("%a %d %b %y %R %z")
  end

  def admin_date(date)
    return "-" if date.nil?

    date.strftime("%a %d %b %y")
  end
end
