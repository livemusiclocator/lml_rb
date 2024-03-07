# frozen_string_literal: true

json.links do
  @links.each do | link |
    json.set! link[:id] do
      json.href link[:href]
      json.templated true if link[:templated]
    end
  end
end
