# frozen_string_literal: true

require "rails_helper"

describe "backstage search" do
  before do
    host! "www.livemusiclocator.com.au"
    sign_in create(:lml_user)
  end

  it "names each act the way a set line does" do
    act = create(:lml_act, name: "Amyl and the Sniffers", country: "Australia", location: "melbourne")

    get "/backstage/search/acts", params: { q: "amyl" }

    expect(JSON.parse(response.body)).to eq(
      [
        {
          "id" => act.id,
          "label" => "Amyl and the Sniffers (Australia)",
          "set_list_name" => "Amyl and the Sniffers (melbourne/Australia)",
        },
      ],
    )
  end
end
