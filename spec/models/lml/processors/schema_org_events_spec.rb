require "rails_helper"

describe Lml::Processors::SchemaOrgEvents do
  describe "process!" do
    it "creates gigs and venues" do
      upload = double("upload", content: File.read("spec/files/schema_org_events.json"))
      Lml::Processors::SchemaOrgEvents.new(upload).process!
    end
  end
end
