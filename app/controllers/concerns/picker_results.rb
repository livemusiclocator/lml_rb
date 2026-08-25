# frozen_string_literal: true

# Renders the { id:, label: } pairs every autocomplete picker consumes - the
# ActiveAdmin forms on the api subdomain and the backstage proposal forms on
# www. Both sides ask the model for `search_label` so a given record reads the
# same wherever it is picked.
#
# A caller that needs more than the pair can pass a block returning extra keys
# for each record. Keep that opt in: every picker parses this shape, so a key
# only one of them understands should only be sent where it is wanted.
module PickerResults
  RESULT_LIMIT = 10

  private

  def render_picker_results(scope)
    results = scope.limit(RESULT_LIMIT).map do |record|
      pair = { id: record.id, label: record.search_label }
      block_given? ? pair.merge(yield(record)) : pair
    end

    render json: results
  end
end
