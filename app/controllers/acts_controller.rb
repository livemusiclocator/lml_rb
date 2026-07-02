# frozen_string_literal: true

class ActsController < ApplicationController
  def autocomplete
    @acts = Lml::Act.order(:name)
  end

  def search
    q = params[:q].to_s.strip
    acts = Lml::Act.order(:name)
    acts = acts.where("LOWER(name) LIKE LOWER(?)", "%#{q}%") if q.present?
    @acts = acts.limit(10)
  end
end

