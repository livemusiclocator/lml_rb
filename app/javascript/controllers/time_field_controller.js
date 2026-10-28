import { Controller } from "@hotwired/stimulus"

const HINT = "Try something like 8pm, 8:30pm or 20:30"
const INVALID = ["border-red-500", "ring-2", "ring-red-200"]

// A plain text box for a time of day, instead of the browser's time picker.
// Takes it however it is typed - 8pm, 8.30pm, 830pm, 20:30 - and rewrites it
// as "8:30pm" on the way out, so you can see what it was read as. A bare hour
// with no am/pm is an evening: these are gig times, and "8" means 8pm. A
// leading zero or a 24 hour time says otherwise.
//
// Something it cannot read is marked invalid, which stops the form submitting.
export default class extends Controller {
  connect() {
    this.tidy()
  }

  tidy() {
    const raw = this.element.value.trim()
    const minutes = parse(raw)

    if (raw && minutes === null) {
      this.element.setCustomValidity(HINT)
      this.element.classList.add(...INVALID)
      return
    }

    this.element.setCustomValidity("")
    this.element.classList.remove(...INVALID)
    if (minutes === null || format(minutes) === this.element.value) return

    this.element.value = format(minutes)
    // Set from script, so nothing hears it otherwise - the set rows listen for
    // input to keep their textarea in step.
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }
}

function parse(text) {
  const value = text.toLowerCase().replace(/\s+/g, "").replace(/\./g, ":").replace(/:(?=[ap])/, "")
  if (value === "noon") return 12 * 60
  if (value === "midnight") return 0

  const match = value.match(/^(\d{1,2})(?::?(\d{2}))?(am|pm|a|p)?m?$/)
  if (!match) return null

  const [, hourText, minuteText = "0", meridiem] = match
  let hour = Number(hourText)
  const minute = Number(minuteText)
  if (minute > 59) return null

  if (meridiem) {
    if (hour < 1 || hour > 12) return null
    hour = hour % 12 + (meridiem.startsWith("p") ? 12 : 0)
  } else {
    if (hour > 23) return null
    if (hour >= 1 && hour <= 11 && !hourText.startsWith("0")) hour += 12
  }

  return hour * 60 + minute
}

function format(minutes) {
  const hour = Math.floor(minutes / 60)
  const minute = String(minutes % 60).padStart(2, "0")
  return `${hour % 12 || 12}:${minute}${hour < 12 ? "am" : "pm"}`
}
