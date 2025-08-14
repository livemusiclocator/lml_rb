# frozen_string_literal: true

# app/models/web/series_theme.rb
module Web
  class SeriesTheme < ApplicationRecord
    belongs_to :explorer_config, class_name: "Web::ExplorerConfig"

    validates :series_name, presence: true
  end
end
