# frozen_string_literal: true

class GigsController < ApplicationController
  def query
    @gigs = Lml::Gig.all
  end
end
