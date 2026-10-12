# frozen_string_literal: true

require "rails_helper"

# arctic_admin parked the filters in an off-canvas drawer behind a funnel icon,
# so every filter took a click to reach and an applied one was invisible. The
# hand-written admin stylesheet keeps them on screen at every width: beside the
# table on a wide screen, above it on a narrow one. Capybara counts an element
# translated off the edge of the page as visible, so this asks the browser
# where the field actually is.
describe "admin index filters", type: :system do
  before do
    @password = "supersecret123"
    @admin_user = Lml::AdminUser.create!(
      email: "admin_filters_visible_spec@example.com",
      username: "filterer",
      password: @password,
      password_confirmation: @password,
      time_zone: "Australia/Melbourne",
    )
  end

  def sign_in_as_admin
    visit "/admin/login"
    fill_in "admin_user_email", with: @admin_user.email
    fill_in "admin_user_password", with: @password
    find("input[type=submit]").click

    raise "admin sign in failed" unless page.has_no_css?("#admin_user_password")
  end

  def on_screen?(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const rect = document.querySelector(#{selector.to_json}).getBoundingClientRect();
        return rect.width > 0 && rect.left >= 0 && rect.right <= window.innerWidth;
      })()
    JS
  end

  { "a wide screen" => [1400, 1000], "a phone" => [390, 844] }.each do |screen, (width, height)|
    context "on #{screen}" do
      before do
        page.driver.resize(width, height)
        sign_in_as_admin
        visit "/admin/gigs"
      end

      it "shows the filters without a click" do
        expect(page).to have_field("q_name_cont")
        expect(on_screen?("#q_name_cont")).to be(true)
      end

      it "filters from the field that is already there" do
        Lml::Gig.create!(name: "Wanted gig", date: Date.today, status: :confirmed)
        Lml::Gig.create!(name: "Other gig", date: Date.today, status: :confirmed)
        visit "/admin/gigs"

        fill_in "q_name_cont", with: "Wanted"
        click_button "Filter"

        expect(page).to have_link("Wanted gig")
        expect(page).to have_no_link("Other gig")
      end
    end
  end
end
