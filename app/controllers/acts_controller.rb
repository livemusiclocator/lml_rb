# frozen_string_literal: true

class ActsController < ApplicationController
  def autocomplete
    @acts = Lml::Act.order(:name)
  end
end

