# frozen_string_literal: true

module Web
  class ErrorsController < ApplicationController
    def not_found
      respond_to do |format|
        format.json { head :not_found }
        format.html { render "404", status: :not_found }
      end
    end

    def gig_not_found
      respond_to do |format|
        format.json { head :not_found }
        format.html { render "404", status: :not_found }
      end
    end
  end
end
