module Lml
  module Formatting
    def self.offset_to_time(offset)
      hours = offset / 60
      mins = offset % 60
      "#{format("%02d", hours)}:#{format("%02d", mins)}"
    end
  end
end
