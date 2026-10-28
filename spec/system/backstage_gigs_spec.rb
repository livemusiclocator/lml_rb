# frozen_string_literal: true

require "rails_helper"

describe "backstage gigs", type: :system do
  before do
    @previous_app_host = Capybara.app_host
    Capybara.app_host = BACKSTAGE_APP_HOST

    @password = "supersecret123"
    @manager = create(:lml_user, password: @password, password_confirmation: @password)
    @venue = create(:lml_venue, name: "The Tote")
    Lml::VenueManager.create!(user: @manager, venue: @venue)

    sign_in_as_manager
    visit "/backstage/venues/#{@venue.id}"
  end

  after { Capybara.app_host = @previous_app_host }

  def sign_in_as_manager
    visit "/backstage/login"
    fill_in "user_email", with: @manager.email
    fill_in "user_password", with: @password
    click_button "Sign in"

    raise "backstage sign in failed" unless page.has_no_css?("#user_password")
  end

  def editor_of(field_id)
    find_field(field_id, visible: :all).ancestor("[data-controller=line-list]")
  end

  def rows_of(field_id)
    editor_of(field_id).all("[data-line-list-row]")
  end

  def set_rows
    rows_of("gig_set_list")
  end

  def paste_into(input, text)
    page.execute_script(<<~JS, input, text)
      const [input, text] = arguments
      const data = new DataTransfer()
      data.setData("text", text)
      input.dispatchEvent(new ClipboardEvent("paste", { clipboardData: data, bubbles: true, cancelable: true }))
    JS
  end

  it "adds a gig to a venue they manage" do
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Gut Health"
    fill_in "Date", with: Date.current + 5
    within(set_rows[0]) do
      fill_in "Act - new or existing", with: "Support Act"
      fill_in "Start", with: "8pm"
    end
    click_button "+ Add a set"
    within(set_rows[1]) do
      fill_in "Act - new or existing", with: "Gut Health"
      fill_in "Start", with: "9:15pm"
      fill_in "Finish", with: "10:30pm"
      fill_in "Stage", with: "Front bar"
    end
    within(rows_of("gig_price_list")[0]) do
      fill_in "Amount", with: "25"
      fill_in "Description, e.g. General admission", with: "General admission"
    end
    click_button "+ Add a price"
    within(rows_of("gig_price_list")[1]) { fill_in "Amount", with: "20" }
    within(rows_of("gig_genre_tag_list")[0]) { fill_in "Genre", with: "post-punk" }
    click_button "+ Add a genre"
    within(rows_of("gig_genre_tag_list")[1]) { fill_in "Genre", with: "indie rock" }
    click_button "Add gig"

    expect(page).to have_content("Added Gut Health.")
    expect(page).to have_content("Support Act, Gut Health")
    gig = @venue.gigs.sole
    expect(gig.date).to eq(Date.current + 5)
    expect(gig.set_list).to eq("Support Act | 20:00 |  | \nGut Health | 21:15 | 22:30 | Front bar")
    expect(gig.price_list).to eq("$25.00 | General admission\n$20.00 | ")
    expect(gig.genre_tags).to eq(["post-punk", "indie rock"])
  end

  it "reads times however they are typed and shows what they were read as" do
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Gut Health"
    fill_in "Date", with: Date.current + 5
    fill_in "Starts", with: "730"
    fill_in "Finishes", with: "11.30 PM"
    within(set_rows[0]) do
      fill_in "Act - new or existing", with: "Gut Health"
      fill_in "Start", with: "9"
      fill_in "Finish", with: "22:15"
    end
    find_field("Gig name / headliner").click

    expect(page).to have_field("Starts", with: "7:30pm")
    expect(page).to have_field("Finishes", with: "11:30pm")
    expect(set_rows[0].find_field("Start").value).to eq("9:00pm")
    expect(set_rows[0].find_field("Finish").value).to eq("10:15pm")
    click_button "Add gig"

    expect(page).to have_content("Added Gut Health.")
    gig = @venue.gigs.sole
    expect([gig.start_time, gig.finish_time]).to eq(["19:30", "23:30"])
    expect(gig.set_list).to eq("Gut Health | 21:00 | 22:15 | ")
  end

  it "does not submit a time it cannot read" do
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Gut Health"
    fill_in "Date", with: Date.current + 5
    fill_in "Starts", with: "late"
    click_button "Add gig"

    expect(page).to have_css("input#gig_start_time:invalid")
    expect(page).to have_no_content("Added Gut Health.")
    expect(@venue.gigs).to be_empty
  end

  it "shows a saved gig's times the same way" do
    gig = create(:lml_gig, venue: @venue, name: "Old name", date: Date.current + 2)
    gig.update!(start_time: "20:00")
    visit "/backstage/gigs/#{gig.id}/edit"

    expect(page).to have_field("Starts", with: "8:00pm")
  end

  # New acts are the common case, so a lineup has to be typable straight through.
  it "moves to a fresh row on enter instead of submitting" do
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Gut Health"
    fill_in "Date", with: Date.current + 5
    within(set_rows[0]) { fill_in "Act - new or existing", with: "First Band" }
    find_field("Act - new or existing", with: "First Band").send_keys(:enter)
    expect(editor_of("gig_set_list")).to have_css("[data-line-list-row]", count: 2)
    expect(page).to have_no_content("Added Gut Health.")

    page.send_keys("Second Band")
    click_button "Add gig"

    expect(page).to have_content("Added Gut Health.")
    expect(page).to have_content("First Band, Second Band")
  end

  it "spreads a pasted lineup across a row per act" do
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Gut Health"
    fill_in "Date", with: Date.current + 5
    paste_into(set_rows[0].find_field("Act - new or existing"), "First Band | 8pm\nSecond Band\n\nThird Band")

    expect(editor_of("gig_set_list")).to have_css("[data-line-list-row]", count: 3)
    expect(set_rows[0].find_field("Start").value).to eq("8pm")
    click_button "Add gig"

    expect(page).to have_content("First Band, Second Band, Third Band")
  end

  # The search fills in the act as a set line names it, so an act with a
  # location is matched rather than duplicated.
  it "picks an existing act from the search" do
    act = create(:lml_act, name: "Amyl and the Sniffers", country: "Australia", location: "melbourne")
    click_on "Add a gig"
    fill_in "Gig name / headliner", with: "Sniffers"
    fill_in "Date", with: Date.current + 5
    within(set_rows[0]) do
      # Typed rather than fill_in, which blurs the box when it is done - and
      # leaving the box closes the search, as it should for a person.
      find_field("Act - new or existing").send_keys("amyl")
      find("[data-autocomplete-target=results] div", text: "Amyl and the Sniffers (Australia)").click
      expect(page).to have_field("Act - new or existing", with: "Amyl and the Sniffers (melbourne/Australia)")
    end
    click_button "Add gig"

    expect(page).to have_content("Added Sniffers.")
    expect(@venue.gigs.sole.sets.sole.act).to eq(act)
  end

  # A 422 render, not a redirect - the case Turbo has to be happy to display.
  it "shows what is missing when the gig cannot be saved" do
    click_on "Add a gig"
    fill_in "Date", with: Date.current + 5
    # The browser would stop a blank required field before it ever got to us.
    page.execute_script("document.getElementById('gig_name').removeAttribute('required')")
    click_button "Add gig"

    expect(page).to have_content("Name can't be blank")
    expect(page).to have_field("Date", with: (Date.current + 5).iso8601)
  end

  it "edits a gig at a venue they manage" do
    gig = create(:lml_gig, venue: @venue, name: "Old name", date: Date.current + 2)
    gig.set_list = "Staying Act | 8:00pm\nLeaving Act"
    visit "/backstage/venues/#{@venue.id}"

    within("li", text: "Old name") { click_on "Edit" }
    fill_in "Gig name / headliner", with: "New name"
    expect(set_rows[0].find_field("Start").value).to eq("8:00pm")
    within(set_rows[1]) { click_button "Remove" }
    click_button "Save gig"

    expect(page).to have_content("Saved New name.")
    expect(gig.reload.set_list).to eq("Staying Act | 20:00 |  | ")
    expect(page).to have_content("New name")
    expect(page).to have_no_content("Old name")
  end
end
