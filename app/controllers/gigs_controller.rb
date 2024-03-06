# frozen_string_literal: true

class GigsController < ApplicationController
  def query
    @gigs = Lml::Gig.confirmed.upcoming
  end
end
