import { Controller } from "@hotwired/stimulus"

// Edits a "one per line" field - sets, prices, genres - a row at a time, and
// keeps the textarea in step as the "a | b | c" lines the model reads. The
// textarea is what submits, and what is left on screen if this never connects,
// so the pipes stay a format for the clipper rather than something a person
// has to type. Each row's [data-field] inputs, in order, are its columns.
export default class extends Controller {
  static targets = ["source", "editor", "rows", "template"]

  connect() {
    this.rowsTarget.innerHTML = ""
    const lines = this.sourceTarget.value.split("\n").filter((line) => line.trim())
    lines.forEach((line) => this._addRow(this._parse(line)))
    if (!lines.length) this._addRow([])

    this.sourceTarget.classList.add("hidden")
    this.editorTarget.classList.remove("hidden")
  }

  add() {
    this._focus(this._addRow([]))
  }

  // Enter moves on to a fresh row rather than submitting the form, so a run of
  // new entries can be typed straight through.
  next(event) {
    event.preventDefault()
    this._focus(this._addRow([], event.target.closest("[data-line-list-row]")))
  }

  // Several lines pasted into a row become a row each, read the way the
  // textarea reads them, so "Gut Health | 8pm" still fills in the time.
  paste(event) {
    const lines = event.clipboardData.getData("text").split(/\r?\n/).filter((line) => line.trim())
    if (lines.length < 2) return

    event.preventDefault()
    let row = event.target.closest("[data-line-list-row]")
    const [first, ...rest] = lines
    this._fill(row, this._parse(first))
    rest.forEach((line) => { row = this._addRow(this._parse(line), row) })
    this.sync()
  }

  remove(event) {
    event.target.closest("[data-line-list-row]").remove()
    this.sync()
  }

  sync() {
    this.sourceTarget.value = this._rows().map((row) => this._line(row)).filter(Boolean).join("\n")
  }

  _rows() {
    return [...this.rowsTarget.querySelectorAll("[data-line-list-row]")]
  }

  _inputs(row) {
    return [...row.querySelectorAll("[data-field]")]
  }

  _parse(line) {
    return line.split("|").map((value) => value.trim())
  }

  _addRow(values, after = null) {
    const row = this.templateTarget.content.firstElementChild.cloneNode(true)
    this._fill(row, values)
    if (after) after.after(row)
    else this.rowsTarget.appendChild(row)
    return row
  }

  _fill(row, values) {
    this._inputs(row).forEach((input, index) => { input.value = values[index] || "" })
  }

  _focus(row) {
    this._inputs(row)[0].focus()
  }

  // A row with nothing in its first column is not an entry. Trailing blanks
  // are dropped so a bare act reads "Gut Health" rather than "Gut Health |  |  | ".
  _line(row) {
    const values = this._inputs(row).map((input) => input.value.replace(/[|\n]/g, " ").trim())
    if (!values[0]) return null

    while (!values[values.length - 1]) values.pop()
    return values.join(" | ")
  }
}
