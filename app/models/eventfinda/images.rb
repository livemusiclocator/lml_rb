# frozen_string_literal: true

module Eventfinda
  class Image
    include ActiveModel::Model

    attr_accessor :original_url, :is_primary, :id, :transforms
  end

  class Images
    def initialize(raw = {})
      if raw[:images]
        @images = raw[:images].map do |raw_image|
          Image.new(raw_image)
        end
      end
      @count = raw[:@count]
    end

    def primary_image
      (@images || []).find(&:is_primary)
    end

    def to_schema_org_builder
      primary_image&.original_url
    end
  end
end
