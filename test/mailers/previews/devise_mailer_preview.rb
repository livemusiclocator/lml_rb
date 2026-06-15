# frozen_string_literal: true

class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(stub_user, "faketoken123")
  end

  def email_changed
    Devise::Mailer.email_changed(stub_user)
  end

  def password_change
    Devise::Mailer.password_change(stub_user)
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(stub_user, "faketoken123")
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(stub_user, "faketoken123")
  end

  private

  def stub_user
    Lml::User.new(email: "preview@livemusiclocator.com.au", display_name: "Preview User")
  end
end
