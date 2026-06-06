import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "results"]
  static values = {
    url: String,
    param: { type: String, default: "q" },
    extras: { type: String, default: "" }
  }

  connect() {
    this._onClickOutside = this._onClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this._onClickOutside)
  }

  search() {
    clearTimeout(this._debounce)
    this._debounce = setTimeout(() => this._fetch(), 250)
  }

  clear() {
    // Only clear the hidden ID if the text was manually wiped
    if (!this.inputTarget.value.trim()) {
      this.hiddenTarget.value = ""
    }
  }

  async _fetch() {
    const q = this.inputTarget.value.trim()
    if (q.length < 2) { this._close(); return }

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set(this.paramValue, q)

    if (this.extrasValue) {
      this.extrasValue.split(",").forEach(pair => {
        const [selector, paramName] = pair.trim().split(":")
        const el = document.querySelector(selector)
        if (el?.value) url.searchParams.set(paramName, el.value)
      })
    }

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      const results = await response.json()
      this._render(results)
    } catch {
      this._close()
    }
  }

  _render(results) {
    this.resultsTarget.innerHTML = ""
    if (!results.length) { this._close(); return }

    results.forEach(({ id, label }) => {
      const div = document.createElement("div")
      div.className = "px-3 py-2 cursor-pointer hover:bg-indigo-50 text-sm text-gray-900"
      div.textContent = label
      div.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this._select(id, label)
      })
      this.resultsTarget.appendChild(div)
    })

    this.resultsTarget.classList.remove("hidden")
    document.addEventListener("click", this._onClickOutside)
  }

  _select(id, label) {
    this.hiddenTarget.value = id
    this.inputTarget.value = label
    this._close()
  }

  _close() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
    document.removeEventListener("click", this._onClickOutside)
  }

  _onClickOutside(e) {
    if (!this.element.contains(e.target)) this._close()
  }
}
