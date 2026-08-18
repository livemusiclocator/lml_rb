# frozen_string_literal: true

module Lml
  # Substring search shared by the admin and backstage picker endpoints.
  #
  # Every whitespace separated term has to match at least one of the given
  # columns, so "tote melbourne" finds "The Tote (melbourne)" even though no
  # single column holds both words. The pickers this replaces preloaded the
  # whole table and filtered client side against the joined label, so matching
  # on the label's component columns keeps that behaviour without shipping the
  # table to the browser.
  module Searchable
    extend ActiveSupport::Concern

    class_methods do
      # `columns` is always a model level constant, never anything a request can
      # influence, so interpolating it into the condition is safe.
      def search_terms(query, columns)
        condition = columns.map { |column| "LOWER(#{column}::text) LIKE ?" }.join(" OR ")

        query.to_s.split.reduce(all) do |scope, term|
          scope.where(condition, *(["%#{term.downcase}%"] * columns.size))
        end
      end
    end
  end
end
