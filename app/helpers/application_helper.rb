# frozen_string_literal: true

module ApplicationHelper
  COPY_SCRIPT = <<~JS.squish.freeze
    navigator.clipboard.writeText(this.dataset.url).then(() => {
      this.textContent = 'Copied!';
      setTimeout(() => { this.textContent = 'Copy link' }, 2000)
    })
  JS

  # A gig, venue or act's lml.live short link, and a button copying it. The
  # script is inline rather than a Stimulus controller so the same markup works
  # in ActiveAdmin, which loads none of backstage's javascript.
  def short_link_with_copy(record, link_class: nil, button_class: nil)
    url = record.short_url
    safe_join(
      [
        link_to(url.delete_prefix("https://"), url, target: "_blank", rel: "noopener", class: link_class),
        copy_link_button(record, class: button_class),
      ],
      " ",
    )
  end

  def copy_link_button(record, **options)
    button_tag("Copy link", type: "button", data: { url: record.short_url }, onclick: COPY_SCRIPT, **options)
  end
end
