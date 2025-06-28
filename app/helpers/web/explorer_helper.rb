module Web
  module ExplorerHelper
  def spa_javascript_tag
    return unless Rails.application.config.spa_assets['spa.js']

    javascript_include_tag(
      Rails.application.config.spa_assets['spa.js'],
      type: 'module',
      'data-turbo-track': 'reload'
    )
  end

  def spa_stylesheet_tag
    return unless Rails.application.config.spa_assets['spa.css']

    stylesheet_link_tag(
      Rails.application.config.spa_assets['spa.css'],
      'data-turbo-track': 'reload'
    )
  end

  def spa_preload_tags
    tags = []

    if Rails.application.config.spa_assets['spa.js']
      tags << preload_link_tag(
        Rails.application.config.spa_assets['spa.js'],
        as: :script
      )
    end

    if Rails.application.config.spa_assets['spa.css']
      tags << preload_link_tag(
        Rails.application.config.spa_assets['spa.css'],
        as: :style
      )
    end

    safe_join(tags)
  end
end
end
