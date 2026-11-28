# frozen_string_literal: true

module Backstage
  class DashboardController < ApplicationController
    def index
      @pending = current_user.proposals.pending.order(created_at: :desc).limit(10)
      @recent = current_user.proposals.where.not(status: :pending).order(reviewed_at: :desc).limit(10)
      @managed_venues = current_user.managed_venues
      @managed_acts = current_user.managed_acts
      @to_review = Lml::Gig.where(checked: [false, nil], hidden: [false, nil], date: Date.current..)
                           .where(uploaded_by: current_user).count if current_user.admin?
    end
  end
end
