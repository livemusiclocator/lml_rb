# frozen_string_literal: true

# Renders the { id:, label: } pairs every autocomplete picker consumes - the
# ActiveAdmin forms on the api subdomain and the backstage proposal forms on
# www. Both sides ask the model for `search_label` so a given record reads the
# same wherever it is picked.
module PickerResults
  RESULT_LIMIT = 10

  private

  def render_picker_results(scope)
    results = scope.limit(RESULT_LIMIT).map do |record|
      { id: record.id, label: record.search_label }
    end

    render json: results
  end
end
