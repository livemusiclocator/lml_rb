# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lml::Sheet do
  def url
    "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit#gid=0"
  end

  def value_range(values)
    Google::Apis::SheetsV4::ValueRange.new(values: values)
  end

  def worksheet_properties(title, sheet_id)
    Google::Apis::SheetsV4::Sheet.new(
      properties: Google::Apis::SheetsV4::SheetProperties.new(title: title, sheet_id: sheet_id),
    )
  end

  before do
    @service = instance_double(Google::Apis::SheetsV4::SheetsService)

    allow(@service).to receive(:get_spreadsheet).and_return(
      Google::Apis::SheetsV4::Spreadsheet.new(sheets: [worksheet_properties("venues", 42)]),
    )
    allow(@service).to receive(:batch_update_values)
    allow(@service).to receive(:batch_update_spreadsheet)

    # pause: 0 because the one second a real run takes per row is deliberate, not something to wait
    # through twenty times here.
    @sheet = described_class.new(url, service: @service, pause: 0)
  end

  describe ".id_from_url" do
    it "takes the id out of a sheet url" do
      expect(described_class.id_from_url(url)).to eq("1AbC_dEf-123")
    end

    it "refuses anything that is not one" do
      expect { described_class.id_from_url("https://example.com/nope") }
        .to raise_error(described_class::InvalidUrlError, /not a google sheets url/)
    end
  end

  describe ".column_letter" do
    it "counts past Z the way sheets does" do
      expect((0..27).map { |index| described_class.column_letter(index) })
        .to eq(%w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB])
    end
  end

  describe "#rows" do
    it "keys every data row by its header" do
      allow(@service).to receive(:get_spreadsheet_values).and_return(
        value_range([%w[name address], ["The Espy", "11 The Esplanade"]]),
      )

      expect(@sheet.rows(worksheet: "venues"))
        .to eq([{ "name" => "The Espy", "address" => "11 The Esplanade" }])
    end

    it "pads a ragged row so every hash carries every header" do
      allow(@service).to receive(:get_spreadsheet_values).and_return(
        value_range([%w[name address venue_id], ["The Espy"]]),
      )

      expect(@sheet.rows(worksheet: "venues"))
        .to eq([{ "name" => "The Espy", "address" => nil, "venue_id" => nil }])
    end

    it "reads an empty sheet as no rows rather than raising" do
      allow(@service).to receive(:get_spreadsheet_values).and_return(value_range(nil))

      expect(@sheet.rows(worksheet: "venues")).to eq([])
    end

    it "quotes a worksheet title containing an apostrophe" do
      allow(@service).to receive(:get_spreadsheet_values).and_return(value_range([["name"]]))

      @sheet.rows(worksheet: "mark's venues")

      expect(@service).to have_received(:get_spreadsheet_values).with(anything, "'mark''s venues'!A:ZZ")
    end
  end

  describe "#ensure_headers" do
    before do
      allow(@service).to receive(:get_spreadsheet_values).and_return(
        value_range([%w[name address], ["The Espy", "11 The Esplanade"]]),
      )
    end

    it "appends only the headers the worksheet does not have" do
      @sheet.ensure_headers(worksheet: "venues", headers: %w[name venue_id import_status])

      expect(@service).to have_received(:batch_update_values) do |_id, request|
        expect(request.data.map { |range| [range.range, range.values] }).to eq(
          [
            ["'venues'!C1", [["venue_id"]]],
            ["'venues'!D1", [["import_status"]]],
          ],
        )
      end
    end

    it "writes nothing when they are all already there" do
      @sheet.ensure_headers(worksheet: "venues", headers: %w[name address])

      expect(@service).not_to have_received(:batch_update_values)
    end

    it "makes the new columns writable straight away" do
      @sheet.ensure_headers(worksheet: "venues", headers: %w[venue_id])

      expect { @sheet.write_row(worksheet: "venues", index: 0, cells: { "venue_id" => "abc" }) }
        .not_to raise_error
    end
  end

  describe "#write_row" do
    before do
      allow(@service).to receive(:get_spreadsheet_values).and_return(
        value_range([%w[name venue_id], ["The Espy", nil]]),
      )
    end

    def requests_from_write(**args)
      captured = nil
      allow(@service).to receive(:batch_update_spreadsheet) { |_id, request| captured = request.requests }

      @sheet.write_row(worksheet: "venues", **args)

      captured
    end

    it "writes a cell into the row's own line, offset past the header" do
      requests = requests_from_write(index: 3, cells: { "venue_id" => "abc" })

      range = requests.first.update_cells.range

      expect(range.sheet_id).to eq(42)
      # Row 3 of the data is spreadsheet row 5, which is index 4 in the zero based, end exclusive
      # ranges the grid api takes.
      expect([range.start_row_index, range.end_row_index]).to eq([4, 5])
      expect([range.start_column_index, range.end_column_index]).to eq([1, 2])
      expect(requests.first.update_cells.rows.first.values.first.user_entered_value.string_value).to eq("abc")
    end

    it "leaves a cell alone rather than blanking it when there is nothing to write" do
      requests = requests_from_write(index: 0, cells: { "venue_id" => nil }, colour: :done)

      expect(requests.map { |request| request.update_cells.nil? }).to eq([true])
    end

    it "colours the whole row so its state is visible from anywhere in a wide sheet" do
      requests = requests_from_write(index: 0, colour: :attention)

      range = requests.first.repeat_cell.range

      expect([range.start_column_index, range.end_column_index]).to eq([0, 2])
      expect(requests.first.repeat_cell.cell.user_entered_format.background_color)
        .to eq(described_class::BACKGROUNDS.fetch(:attention))
    end

    it "does not touch a row with nothing to write and no colour" do
      @sheet.write_row(worksheet: "venues", index: 0, cells: { "venue_id" => nil }, colour: nil)

      expect(@service).not_to have_received(:batch_update_spreadsheet)
    end

    it "refuses to write a column that was never created" do
      expect { @sheet.write_row(worksheet: "venues", index: 0, cells: { "import_status" => "created" }) }
        .to raise_error(described_class::UnknownColumnError, /venues has no import_status column/)
    end
  end
end
