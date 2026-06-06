# frozen_string_literal: true

class ProposalMailer < ApplicationMailer
  def approved(proposal)
    @proposal = proposal
    @user = proposal.user
    mail(to: @user.email, subject: "Your proposal has been approved")
  end

  def rejected(proposal)
    @proposal = proposal
    @user = proposal.user
    mail(to: @user.email, subject: "Your proposal was not accepted")
  end
end
