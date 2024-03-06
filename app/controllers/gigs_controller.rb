# frozen_string_literal: true

class GigsController < ApplicationController
  def query
    @gigs = Lml::Gig.status_confirmed.upcoming
  end
end
