# frozen_string_literal: true

module Eventfinda
  def self.to_schema_org_events(events)
    Jbuilder.new do |result|
      result.array!(events) { |event| result.merge! event.to_schema_org_builder }
    end.target!
  end
end
