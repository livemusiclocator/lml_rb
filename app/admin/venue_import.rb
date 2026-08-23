# frozen_string_literal: true

# Deliberately not in the menu - `menu false`. This spends money (one Places
# lookup per new row) and writes into somebody's spreadsheet, so it is reached
# by knowing the URL rather than by browsing past it.
#
#   /admin/venue_import
#
# See doc/google_sheets_venue_import.md for the sheet's columns and the
# credentials this needs.
ActiveAdmin.register_page "Venue Import" do
  menu false

  content title: "Import venues from a Google Sheet" do
    para do
      text_node "Reads the "
      strong "venues"
      text_node " worksheet, resolves each row through the Places API, and writes the outcome " \
                "back into the row it came from. A row that already has a "
      strong "venue_id"
      text_node " is skipped, so this is safe to run again after adding rows."
    end

    # The two things that actually stop this working, answered before it is run
    # rather than as a stack trace afterwards.
    panel "Before you run it" do
      email = begin
        Lml::Sheet.service_account_email
      rescue StandardError
        nil
      end

      if email
        para do
          text_node "Share the sheet (as an editor - it writes results back) with:"
          br
          strong email
        end
      else
        para do
          strong "GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS is not set here, so this cannot read any sheet."
        end
      end

      unless ENV.fetch("GOOGLE_PLACES_SERVER_KEY", nil).present?
        para do
          strong "GOOGLE_PLACES_SERVER_KEY is not set here, so no row can be resolved."
        end
      end

      para class: "inline-hints" do
        text_node "Rows are processed one at a time and each one waits on Google, so a long sheet " \
                  "can outlast the request. If this page times out the run carries on - watch the " \
                  "sheet, which is coloured row by row as it goes, and re-run it afterwards to pick " \
                  "up whatever was left."
      end
    end

    panel "Run an import" do
      form action: admin_venue_import_run_path, method: :post do
        text_node hidden_field_tag(:authenticity_token, form_authenticity_token)
        label "Spreadsheet URL", for: "sheet_url"
        br
        text_node text_field_tag(:sheet_url, params[:sheet_url], id: "sheet_url", size: 90,
                                                                 placeholder: "https://docs.google.com/spreadsheets/d/.../edit",)
        br
        br
        input type: :submit, value: "Import venues"
      end
    end
  end

  page_action :run, method: :post do
    url = params[:sheet_url].to_s.strip

    if url.empty?
      redirect_to admin_venue_import_path, alert: "Paste the spreadsheet's URL first."
      next
    end

    begin
      counts = Lml::VenueImport.call(url)
      redirect_to admin_venue_import_path(sheet_url: url), notice: "Imported: #{describe(counts)}."
    rescue Lml::Sheet::InvalidUrlError
      redirect_to admin_venue_import_path(sheet_url: url),
                  alert: "That is not a Google Sheets URL - it should look like " \
                         "https://docs.google.com/spreadsheets/d/.../edit"
    rescue StandardError => e
      # Anything Google refused: the sheet is not shared, there is no `venues`
      # worksheet, Places is not enabled, billing is off. The message is the only
      # useful thing here, and it belongs on screen rather than in the log.
      Rails.logger.error("Venue import failed: #{e.class}: #{e.message}")
      redirect_to admin_venue_import_path(sheet_url: url), alert: "#{e.class}: #{e.message}"
    end
  end

  controller do
    private

    # { "created" => 2, "ambiguous" => 1 } => "2 created, 1 ambiguous"
    def describe(counts)
      return "nothing - the sheet had no rows to process" if counts.blank?

      counts.map { |outcome, count| "#{count} #{outcome}" }.join(", ")
    end
  end
end
