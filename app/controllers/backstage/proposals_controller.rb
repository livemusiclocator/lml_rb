# frozen_string_literal: true

module Backstage
  class ProposalsController < ApplicationController
    def index
      @proposals = current_user.proposals.order(created_at: :desc)
    end

    def show
      @proposal = current_user.proposals.find(params[:id])
    end

    def new
      @proposal = Lml::Proposal.new
      @target = find_target
    end

    def create
      target = find_target
      proposed_attrs = proposal_params[:proposed_attributes].to_h.reject { |_, v| v.blank? }

      if target && current_user_manages?(target.is_a?(Lml::Set) ? target.gig.venue : target)
        apply_directly(target, proposed_attrs)
      else
        submit_proposal(target, proposed_attrs)
      end
    end

    private

    def find_target
      return nil unless params[:target_type].present? && params[:target_id].present?

      klass = { "Lml::Gig" => Lml::Gig, "Lml::Act" => Lml::Act, "Lml::Venue" => Lml::Venue }[params[:target_type]]
      klass&.find_by(id: params[:target_id])
    end

    def proposal_params
      params.require(:proposal).permit(
        :note,
        :proposed_type,
        proposed_attributes: [
          :name, :date, :venue_id, :description, :url, :ticketing_url,
          :start_time, :finish_time, :series, :set_list,
          genre_tags: [], proposed_genre_tags: [], information_tags: [],
        ],
      )
    end

    def apply_directly(target, attrs)
      if target.update(attrs)
        redirect_to backstage_root_path, notice: "Changes applied directly — you manage this #{target.class.name.demodulize.downcase}."
      else
        redirect_to new_backstage_proposal_path(target_type: target.class.name, target_id: target.id),
                    alert: "Could not apply changes: #{target.errors.full_messages.to_sentence}"
      end
    end

    def submit_proposal(target, attrs)
      proposal = current_user.proposals.build(
        target: target,
        proposed_type: target ? target.class.name : proposal_params[:proposed_type],
        proposed_attributes: attrs,
        note: proposal_params[:note],
      )

      if proposal.save
        redirect_to backstage_proposal_path(proposal), notice: "Proposal submitted — thanks! We'll review it shortly."
      else
        redirect_to new_backstage_proposal_path, alert: "Could not submit proposal: #{proposal.errors.full_messages.to_sentence}"
      end
    end
  end
end
