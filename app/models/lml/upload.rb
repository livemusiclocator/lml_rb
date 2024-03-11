module Lml
  class Upload < ApplicationRecord
    def self.ransackable_attributes(_auth_object = nil)
      %w[format source]
    end

    def self.ransackable_associations(_auth_object = nil)
      []
    end

    enum :format, { clipper: "clipper" }, prefix: true

    validates :format, presence: true
    validates :source, presence: true
    validates :content, presence: true

    def process!
      return unless valid?

      case format
      when "clipper"
        Lml::Processors::Clipper.new(self).process!
      end
    end
  end
end
