import { Controller } from "@hotwired/stimulus"

// Polls /admin/stats/export/status while a background report export runs and
// drives the progress bar. When the job finishes, swaps the in-flight block
// for a download link; on failure, shows the error.
export default class extends Controller {
  static targets = ["progress", "bar", "status", "error", "download", "downloadLink", "rows"]
  static values = {
    statusUrl: String,
    id: Number,
    state: { type: String, default: "idle" },
    errorPrefix: { type: String, default: "Export failed" }
  }

  static POLL_INTERVAL_MS = 1000
  static MAX_FAILURES = 10

  connect() {
    this.failures = 0

    if (this.idValue && (this.stateValue === "pending" || this.stateValue === "running")) {
      this.pollTimer = window.setInterval(() => this.poll(), this.constructor.POLL_INTERVAL_MS)
      this.poll()
    }
  }

  disconnect() {
    window.clearInterval(this.pollTimer)
  }

  async poll() {
    try {
      const response = await fetch(`${this.statusUrlValue}?id=${this.idValue}`, {
        headers: { Accept: "application/json" }
      })
      if (response.status === 404) {
        window.clearInterval(this.pollTimer)
        this.showError("not found")
        return
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      this.failures = 0
      this.update(await response.json())
    } catch (error) {
      this.failures += 1
      if (this.failures >= this.constructor.MAX_FAILURES) {
        window.clearInterval(this.pollTimer)
        this.showError(String(error))
      }
    }
  }

  // Fired on click of an export button: show the "report is being generated"
  // hint right away, before the server swaps the panel in.
  start() {
    this.statusTarget.classList.remove("hidden")
  }

  update(data) {
    if (data.status === "pending" || data.status === "running") {
      this.statusTarget.classList.remove("hidden")
      this.progressTarget.classList.remove("hidden")
      this.errorTarget.classList.add("hidden")
      this.downloadTarget.classList.add("hidden")
      this.barTarget.style.width = `${data.progress}%`
      this.progressTarget.setAttribute("aria-valuenow", data.progress)
      return
    }

    window.clearInterval(this.pollTimer)

    if (data.status === "done") {
      this.statusTarget.classList.add("hidden")
      this.progressTarget.classList.add("hidden")
      this.errorTarget.classList.add("hidden")
      this.downloadTarget.classList.remove("hidden")
      if (data.download_url) this.downloadLinkTarget.href = data.download_url
    } else if (data.status === "failed") {
      this.showError(data.error)
    }
  }

  showError(message) {
    const detail = message ? `: ${message}` : ""
    this.statusTarget.classList.add("hidden")
    this.progressTarget.classList.add("hidden")
    this.downloadTarget.classList.add("hidden")
    this.errorTarget.textContent = `${this.errorPrefixValue}${detail}`
    this.errorTarget.classList.remove("hidden")
  }
}
