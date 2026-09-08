# frozen_string_literal: true

module Web
  class ErrorsController < ApplicationController
    def not_found
      respond_to do |format|
        format.json { head :not_found }
        format.html { render "404", status: :not_found }
        # Bots arrive with no Accept header or a nonsense one, matching neither of the above, and
        # respond_to raises UnknownFormat rather than falling through. So the 404 handler itself
        # errored - a second backtrace in the log, and a 406 where a 404 was meant.
        format.any { head :not_found }
      end
    end

    def gig_not_found
      respond_to do |format|
        format.json { head :not_found }
        format.html { render "404", status: :not_found }
        format.any { head :not_found }
      end
    end
  end
end
