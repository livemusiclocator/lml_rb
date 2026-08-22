# frozen_string_literal: true

require "rails_helper"

describe "admin users" do
  before { host! "api.lml.live" }

  before do
    @admin_user = Lml::AdminUser.create!(
      email: "admin_users_spec@example.com",
      username: "old_username",
      password: "supersecret123",
      password_confirmation: "supersecret123",
      time_zone: "Australia/Melbourne",
    )
    sign_in @admin_user, scope: :admin_user
  end

  it "updates the username without requiring a password change" do
    patch "/admin/admin_users/#{@admin_user.id}", params: {
      lml_admin_user: {
        email: @admin_user.email,
        username: "new_username",
        time_zone: @admin_user.time_zone,
        password: "",
        password_confirmation: "",
      },
    }

    expect(response).to redirect_to("/admin/admin_users/#{@admin_user.id}")
    expect(@admin_user.reload.username).to eq("new_username")
  end

  it "grants admin access to a backstage user" do
    user = create(:lml_user)

    post "/admin/users/#{user.id}/grant_admin"

    expect(response).to redirect_to("/admin/users/#{user.id}")
    expect(user.reload.admin?).to be(true)
  end

  it "revokes admin access from a backstage user" do
    user = create(:lml_user, :admin)

    delete "/admin/users/#{user.id}/revoke_admin"

    expect(response).to redirect_to("/admin/users/#{user.id}")
    expect(user.reload.admin?).to be(false)
  end
end
