# frozen_string_literal: true

require "google/apis/sheets_v4"
require "googleauth"

module Lml
  # Reads and writes one worksheet of a Google Sheet.
  #
  # Authenticates as a service account, so there is no user to consent and no oauth callback -
  # access comes from the sheet being shared with the service account's address as an *editor*. Find
  # that address with:
  #
  #   echo $GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS | base64 -d | jq -r .client_email
  #
  # A sheet that has not been shared reads as a 404 rather than a 403, because an unshared document
  # is invisible rather than forbidden.
  #
  # See doc/google_sheets_venue_import.md.
  class Sheet
    CREDENTIALS_VAR = "GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS"

    SCOPE = "https://www.googleapis.com/auth/spreadsheets"

    URL_PATTERN = %r{/spreadsheets/d/(?<id>[A-Za-z0-9_-]+)}

    # Headers live in row 1, so the first row of data is row 2.
    HEADER_ROW = 1
    FIRST_DATA_ROW = HEADER_ROW + 1

    # How long to wait after writing a row. See #write_row for why this is deliberately slow.
    ROW_PAUSE = 1

    # What a row is coloured once it has been processed. Sheets takes each channel as a fraction
    # rather than a byte, so these are the pastels its toolbar calls light green 3 (#d9ead3) and
    # light yellow 3 (#fff2cc).
    BACKGROUNDS = {
      done: Google::Apis::SheetsV4::Color.new(red: 0.851, green: 0.918, blue: 0.827),
      attention: Google::Apis::SheetsV4::Color.new(red: 1.0, green: 0.949, blue: 0.8),
    }.freeze

    class InvalidUrlError < StandardError; end

    # Writing a row at a time can only address columns that already exist, so this means
    # ensure_headers was not called with everything that was later written.
    class UnknownColumnError < StandardError; end

    def self.id_from_url(url)
      match = URL_PATTERN.match(url.to_s)

      raise InvalidUrlError, "#{url.inspect} is not a google sheets url" if match.nil?

      match[:id]
    end

    # "A", "B", .. "Z", "AA", "AB", .. for a zero-based column index.
    def self.column_letter(index)
      letters = ""
      remaining = index

      loop do
        letters = ("A".ord + (remaining % 26)).chr + letters
        remaining = (remaining / 26) - 1
        break if remaining.negative?
      end

      letters
    end

    # The address a sheet has to be shared with. Read out of the credential rather than written
    # down, so it cannot go stale when the key is rotated. Nil where the credential is not
    # configured, which is every machine that has not been set up yet.
    def self.service_account_email
      encoded = ENV.fetch(CREDENTIALS_VAR, nil)

      return if encoded.blank?

      JSON.parse(Base64.decode64(encoded))["client_email"]
    end

    # The key is held base64 encoded in one env var so there is no secret file to deploy. The sheets
    # client takes an IO, so it never has to touch the disk either.
    def self.credentials
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(Base64.decode64(ENV.fetch(CREDENTIALS_VAR))),
        scope: [SCOPE],
      )
    end

    def self.default_service
      service = Google::Apis::SheetsV4::SheetsService.new
      service.authorization = credentials
      service
    end

    def initialize(url, service: self.class.default_service, pause: ROW_PAUSE)
      @id = self.class.id_from_url(url)
      @service = service
      @pause = pause
      @headers = {}
    end

    # Every data row of the worksheet as a hash keyed by its column header. Ragged rows are padded,
    # so every hash carries every header whether or not that cell had anything in it.
    def rows(worksheet:)
      header_row, *data_rows = raw_values(worksheet)

      return [] if header_row.nil?

      @headers[worksheet] = header_row

      data_rows.map do |data_row|
        header_row.each_with_index.to_h { |header, index| [header, data_row[index].presence] }
      end
    end

    # Adds any of these headers the worksheet does not have yet, appended to the end of its header
    # row. Writing a row at a time means every column has to exist before the first row is written,
    # rather than being claimed by whichever value happened to be written into it first.
    def ensure_headers(worksheet:, headers:)
      missing = headers - header_row(worksheet)

      return if missing.empty?

      data = missing.each_with_index.map do |header, offset|
        letter = self.class.column_letter(header_row(worksheet).length + offset)

        value_range(worksheet, "#{letter}#{HEADER_ROW}", header)
      end

      @service.batch_update_values(
        @id,
        Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(
          data: data,
          # RAW, not USER_ENTERED - everything written here is a literal uuid or a sentence, so
          # there is nothing to gain from letting Sheets reinterpret it as a formula or a date.
          value_input_option: "RAW",
        ),
      )

      header_row(worksheet).concat(missing)
    end

    # Writes the given cells of one data row and colours the row, in a single request. `index` is
    # the row's place in what #rows returned. A nil value leaves that cell alone rather than
    # blanking it, so this never destroys work someone has already done in the sheet, and a row with
    # nothing to write and no colour is not touched at all.
    def write_row(worksheet:, index:, cells: {}, colour: nil)
      requests = cells.filter_map { |header, value| value_request(worksheet, index, header, value) }
      requests << colour_request(worksheet, index, colour) if colour

      return if requests.empty?

      @service.batch_update_spreadsheet(
        @id,
        Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(requests: requests),
      )

      # Deliberately slow: a row a second is what makes a run something you can watch happen in the
      # sheet you are already looking at. It also happens to be exactly the sixty writes a minute
      # Sheets allows one account, which is the reason a run of any size would want to go back to
      # writing whole columns in one request instead.
      sleep(@pause) if @pause.positive?
    end

    private

    # Colour requests address a worksheet by its numeric id rather than by title, and that id is
    # only in the spreadsheet's properties.
    def sheet_id(worksheet)
      @sheet_ids ||= @service.get_spreadsheet(@id, fields: "sheets.properties(sheetId,title)").sheets.to_h do |sheet|
        [sheet.properties.title, sheet.properties.sheet_id]
      end

      @sheet_ids.fetch(worksheet)
    end

    def value_request(worksheet, index, header, value)
      return if value.nil?

      Google::Apis::SheetsV4::Request.new(
        update_cells: Google::Apis::SheetsV4::UpdateCellsRequest.new(
          range: grid_range(worksheet, index, column_index(worksheet, header)),
          rows: [
            Google::Apis::SheetsV4::RowData.new(
              values: [
                Google::Apis::SheetsV4::CellData.new(
                  user_entered_value: Google::Apis::SheetsV4::ExtendedValue.new(string_value: value.to_s),
                ),
              ],
            ),
          ],
          fields: "userEnteredValue",
        ),
      )
    end

    # The whole row is coloured rather than only the cells that were written, so that the state of a
    # row is visible whichever part of a wide sheet someone is scrolled to.
    def colour_request(worksheet, index, colour)
      Google::Apis::SheetsV4::Request.new(
        repeat_cell: Google::Apis::SheetsV4::RepeatCellRequest.new(
          range: grid_range(worksheet, index, 0, columns: header_row(worksheet).length),
          cell: Google::Apis::SheetsV4::CellData.new(
            user_entered_format: Google::Apis::SheetsV4::CellFormat.new(
              background_color: BACKGROUNDS.fetch(colour),
            ),
          ),
          fields: "userEnteredFormat.backgroundColor",
        ),
      )
    end

    def grid_range(worksheet, index, column, columns: 1)
      Google::Apis::SheetsV4::GridRange.new(
        sheet_id: sheet_id(worksheet),
        # Zero based and end exclusive here, unlike the A1 ranges the values api takes.
        start_row_index: FIRST_DATA_ROW - 1 + index,
        end_row_index: FIRST_DATA_ROW + index,
        start_column_index: column,
        end_column_index: column + columns,
      )
    end

    def raw_values(worksheet)
      @service.get_spreadsheet_values(@id, "#{quoted(worksheet)}!A:ZZ").values || []
    end

    def value_range(worksheet, cell, value)
      Google::Apis::SheetsV4::ValueRange.new(
        range: "#{quoted(worksheet)}!#{cell}",
        values: [[value]],
      )
    end

    def column_index(worksheet, header)
      header_row(worksheet).index(header) or raise UnknownColumnError, "#{worksheet} has no #{header} column"
    end

    def header_row(worksheet)
      @headers[worksheet] ||= raw_values(worksheet).first || []
    end

    # Worksheet titles are user supplied and a bare apostrophe would end the quoted range early.
    # Sheets escapes one by doubling it.
    def quoted(worksheet)
      "'#{worksheet.gsub("'", "''")}'"
    end
  end
end
