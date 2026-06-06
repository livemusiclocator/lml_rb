# frozen_string_literal: true

ActiveAdmin.register Lml::Proposal, as: "Proposal" do
  menu label: "Proposals", priority: 2

  permit_params :reviewer_note

  filter :status, as: :select, collection: Lml::Proposal.statuses.keys
  filter :user_email, as: :string
  filter :created_at

  index do
    selectable_column
    column :target do |p|
      p.target_label
    end
    column :proposed_fields do |p|
      p.proposed_attributes.keys.join(", ")
    end
    column :user
    column :status do |p|
      status_tag p.status
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :user
      row :target do |p|
        p.target_label
      end
      row :status do |p|
        status_tag p.status
      end
      row :proposed_attributes do |p|
        p.proposed_attributes.map { |k, v| "#{k.humanize}: #{Array(v).join(', ')}" }.join("\n")
      end
      row :note
      row :reviewer_note
      row :reviewed_by
      row :reviewed_at
      row :created_at
    end

    if resource.pending?
      panel "Review" do
        form action: approve_admin_proposal_path(resource), method: :post do |f|
          f.input :_method, type: :hidden, value: :put
          f.input :authenticity_token, type: :hidden, value: form_authenticity_token
          label "Reviewer note (optional)"
          br
          textarea name: :reviewer_note, rows: 2, style: "width:100%;margin-bottom:8px"
          br
          input type: :submit, value: "Approve", style: "margin-right:8px"
        end
        form action: reject_admin_proposal_path(resource), method: :post do |f|
          f.input :_method, type: :hidden, value: :put
          f.input :authenticity_token, type: :hidden, value: form_authenticity_token
          label "Reviewer note (optional)"
          br
          textarea name: :reviewer_note, rows: 2, style: "width:100%;margin-bottom:8px"
          br
          input type: :submit, value: "Reject"
        end
      end
    end
  end

  member_action :approve, method: :put do
    resource.approve!(admin: current_admin_user, note: params[:reviewer_note])
    redirect_to admin_proposal_path(resource), notice: "Proposal approved."
  end

  member_action :reject, method: :put do
    resource.reject!(admin: current_admin_user, note: params[:reviewer_note])
    redirect_to admin_proposal_path(resource), notice: "Proposal rejected."
  end

  action_item :approve, only: :show, if: -> { resource.pending? } do
    link_to "Approve", approve_admin_proposal_path(resource), method: :put,
            data: { confirm: "Approve and apply this proposal?" }
  end

  action_item :reject, only: :show, if: -> { resource.pending? } do
    link_to "Reject", reject_admin_proposal_path(resource), method: :put,
            data: { confirm: "Reject this proposal?" }
  end
end
