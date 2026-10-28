import { Controller } from "@hotwired/stimulus"

// Fills a venue form from Google: from the place picked in the search, or by
// refreshing the place the venue is already linked to. The whole Places
// response rides along in a hidden field so the venue keeps it. Wherever
// Google replaces something that was already there, the field says what it
// was and offers to keep it.
//
// Suggestions and the details for the one place picked share a session token,
// which is what makes the suggestions free; a token is spent once details are
// fetched with it, so each pick starts a new one. A refresh has no
// suggestions, so it sends no token.
export default class extends Controller {
  static targets = ["sessionToken", "payload", "status"]
  // detailsUrl has PLACE_ID standing in for the place. venueUrl is the venue
  // being edited, which Google's place is bound to be "already a venue" as.
  static values = { detailsUrl: String, venueUrl: String }

  connect() {
    if (this.hasSessionTokenTarget) this._newSession()
  }

  // Enter in the search box would otherwise submit a venue nobody has filled in.
  ignore(event) {
    event.preventDefault()
  }

  fill(event) {
    const token = this.sessionTokenTarget.value
    this._newSession()
    this._lookup(event.detail.id, token)
  }

  refresh(event) {
    this._lookup(event.params.id, null)
  }

  async _lookup(id, token) {
    const path = this.detailsUrlValue.replace("PLACE_ID", encodeURIComponent(id))
    const url = new URL(path, window.location.origin)
    if (token) url.searchParams.set("session_token", token)
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
    this.element.querySelectorAll("[data-venue-place-change]").forEach((note) => note.remove())
    let updated = 0

    Object.entries(attributes).forEach(([name, value]) => {
      const field = this.element.elements[`venue[${name}]`]
      if (!field || field.value === String(value)) return

      const was = field.value
      field.value = value
      updated += 1
      if (was.trim()) field.insertAdjacentElement("afterend", this._changeNote(field, was))
    })
    this.payloadTarget.value = JSON.stringify(place)

    if (existing && existing.url !== this.venueUrlValue) {
      this.statusTarget.replaceChildren(this._existingWarning(existing))
    } else {
      this.statusTarget.textContent = updated
        ? "Filled in from Google - check it over before you save."
        : "Google has nothing new for this venue."
    }
  }

  // What a field held before Google's answer replaced it, and a way back.
  _changeNote(field, was) {
    const note = document.createElement("p")
    note.dataset.venuePlaceChange = ""
    note.className = "text-xs text-amber-800 mt-1"

    const keep = document.createElement("button")
    keep.type = "button"
    keep.textContent = "Keep old"
    keep.className = "ml-2 font-medium underline"
    keep.addEventListener("click", () => {
      field.value = was
      note.remove()
    })

    note.append(`Was: ${was}`, keep)
    return note
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
