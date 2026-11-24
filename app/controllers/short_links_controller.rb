# frozen_string_literal: true

# lml.live's short links - see Lml::ShortLink - and the long form
# lml.live/gigs/:uuid the RSS feed has always linked to. Each lands on the gig
# guide's own page for the record.
#
# 302 rather than 301: browsers keep a 301 forever, and where these point may
# well change as the front end settles. The link people share must not.
class ShortLinksController < ApplicationController
  KINDS = { "g" => [Lml::Gig, "gigs"], "v" => [Lml::Venue, "venues"], "a" => [Lml::Act, "acts"] }.freeze

  def show
    model, path = KINDS.fetch(params[:kind])
    records = matching(model)

    case records.size
    when 0 then head :not_found
    when 1 then redirect_to_guide(path, records.first.id)
    else render_choice(records, path)
    end
  end

  def gig
    redirect_to_guide("gigs", params[:id])
  end

  private

  def matching(model)
    range = Lml::ShortLink.id_range(params[:code]) or return []

    model.where(id: range).order(:id).limit(10).to_a
  end

  def redirect_to_guide(path, id)
    redirect_to guide_url(path, id), status: :found, allow_other_host: true
  end

  def guide_url(path, id)
    "#{request.protocol}www.#{params[:target_domain]}/#{path}/#{id}"
  end

  # Two records sharing a code: vanishingly rare, so a plain list will do.
  def render_choice(records, path)
    items = records.map do |record|
      helpers.tag.li(helpers.link_to(record.try(:display_name) || record.name, guide_url(path, record.id)))
    end
    render html: helpers.tag.ul(helpers.safe_join(items)), layout: false
  end
end
