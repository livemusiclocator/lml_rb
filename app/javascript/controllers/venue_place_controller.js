import { Controller } from "@hotwired/stimulus"

// Fills the new venue form from the Google place picked in its search, and
// keeps the whole Places response in a hidden field so the venue holds on to
// everything Google said. Suggestions and the details for the one place picked
// share a session token, which is what makes the suggestions free; a token is
// spent once details are fetched with it, so each pick starts a new one.
export default class extends Controller {
  static targets = ["sessionToken", "payload", "status"]
  // The details path with PLACE_ID standing in for the place picked.
  static values = { detailsUrl: String }

  connect() {
    this._newSession()
  }

  // Enter in the search box would otherwise submit a venue nobody has filled in.
  ignore(event) {
    event.preventDefault()
  }

  async fill(event) {
    const path = this.detailsUrlValue.replace("PLACE_ID", encodeURIComponent(event.detail.id))
    const url = new URL(path, window.location.origin)
    url.searchParams.set("session_token", this.sessionTokenTarget.value)
    this._newSession()
    this.statusTarget.textContent = "Looking it up…"

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error)

      this._apply(result)
    } catch (error) {
      this.statusTarget.textContent = error.message || "Google Places did not answer. Try again, or fill the venue in by hand."
    }
  }

  _apply({ attributes, place, existing }) {
    Object.entries(attributes).forEach(([name, value]) => {
      const field = this.element.elements[`venue[${name}]`]
      if (field) field.value = value
    })
    this.payloadTarget.value = JSON.stringify(place)

    this.statusTarget.replaceChildren(
      existing ? this._existingWarning(existing) : "Filled in from Google - check it over before you save."
    )
  }

  _existingWarning({ name, url }) {
    const span = document.createElement("span")
    const link = document.createElement("a")
    link.href = url
    link.textContent = name
    link.className = "underline font-medium"
    span.append("This place is already a venue: ", link, ".")
    return span
  }

  // A version 4 uuid, which is what Google asks for. Built by hand because
  // crypto.randomUUID only exists on a secure origin, and a dev host like
  // backstage.lml.localhost over http is not one; getRandomValues works anywhere.
  _newSession() {
    const bytes = crypto.getRandomValues(new Uint8Array(16))
    bytes[6] = (bytes[6] & 0x0f) | 0x40
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("")
    this.sessionTokenTarget.value =
      `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
  }
}
