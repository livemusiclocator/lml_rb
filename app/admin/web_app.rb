#!/usr/bin/env ruby
# frozen_string_literal: true

ActiveAdmin.register_page "Web App" do
  menu priority: 10, label: "Web App"

  content title: "Web App Configuration" do
    para "Settings related to the web apps at:"
    a "livemusiclocator.com.au", href: "https://www.livemusiclocator.com.au/", target: "_blank"
  end
end
