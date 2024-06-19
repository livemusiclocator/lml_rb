module Lml
  class Act < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[name country location]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    def self.find_or_create_act_from_line!(line)
      name, location, country = extract_name_location_country(line)
      act = Lml::Act.where("lower(name) = ?", name.downcase).first
      if act
        act.update!(location: location, country: country)
        act
      else
        Lml::Act.create!(name: name, location: location, country: country)
      end
    end

    def self.extract_name_location_country(line)
      match = /(.*) \((.*)\)/.match(line)
      return line unless match

      name = match[1].strip
      location = match[2].strip
      match = %r{(.*)/(.*)}.match(location)

      return [name, location, "Australia"] unless match

      [name, match[1], match[2]]
    end

    def genre_list
      (genres || []).join(", ")
    end

    def genre_list=(value)
      self.genres = value.split(",").map(&:strip)
    end

    def label
      "#{name} (#{country})"
    end
  end
end
