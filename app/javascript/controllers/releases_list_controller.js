import { Controller } from "@hotwired/stimulus"

// Sorts and compacts the admin releases list. Both preferences are stored in
// localStorage so they survive turbo_stream re-renders of the list partial
// (e.g. after bulk actions) and full page reloads.
export default class extends Controller {
  static targets = ["list", "sort", "compactToggle"]

  static SORT_KEY = "admin-releases-sort"
  static COMPACT_KEY = "admin-releases-compact"

  connect() {
    this.applyCompact(this.storedCompact())
    this.applySort(this.storedSort())
  }

  sort() {
    const key = this.sortTarget.value
    this.store(this.constructor.SORT_KEY, key)
    this.applySort(key)
  }

  toggleCompact() {
    this.applyCompact(!this.isCompact())
  }

  applySort(key) {
    if (!key) return
    if (this.sortTarget && this.sortTarget.value !== key) this.sortTarget.value = key

    const items = Array.from(this.listTarget.querySelectorAll(".admin-release"))
    // Stable sort: decorate with the original index to keep ties in place.
    const decorated = items.map((item, index) => [item, index])
    const comparator = this.comparatorFor(key)
    decorated.sort((a, b) => comparator(a[0], b[0]) || a[1] - b[1])
    decorated.forEach(([item]) => this.listTarget.appendChild(item))
  }

  applyCompact(compact) {
    this.listTarget.classList.toggle("admin-releases-list--compact", compact)
    this.store(this.constructor.COMPACT_KEY, compact ? "1" : "0")
    if (this.hasCompactToggleTarget) {
      this.compactToggleTarget.setAttribute("aria-pressed", compact ? "true" : "false")
      this.compactToggleTarget.classList.toggle("is-active", compact)
    }
  }

  isCompact() {
    return this.listTarget.classList.contains("admin-releases-list--compact")
  }

  comparatorFor(key) {
    const collator = new Intl.Collator(undefined, { sensitivity: "base", numeric: true })
    const text = (attr) => (a, b) => collator.compare(a.dataset[attr] || "", b.dataset[attr] || "")
    const number = (attr, direction = 1) => (a, b) =>
      (Number(a.dataset[attr]) || 0) * direction - (Number(b.dataset[attr]) || 0) * direction

    switch (key) {
      case "date_desc": return number("sortDate", -1)
      case "date_asc": return number("sortDate", 1)
      case "created_desc": return number("sortCreated", -1)
      case "created_asc": return number("sortCreated", 1)
      case "title_asc": return text("sortTitle")
      case "title_desc": return (a, b) => text("sortTitle")(b, a)
      case "artist_asc": return text("sortArtist")
      case "artist_desc": return (a, b) => text("sortArtist")(b, a)
      case "plays_desc": return number("sortPlays", -1)
      case "downloads_desc": return number("sortDownloads", -1)
      case "tracks_desc": return number("sortTracks", -1)
      case "duration_desc": return number("sortDuration", -1)
      default: return number("sortCreated", -1)
    }
  }

  storedSort() {
    return this.read(this.constructor.SORT_KEY) || "created_desc"
  }

  storedCompact() {
    return this.read(this.constructor.COMPACT_KEY) === "1"
  }

  read(key) {
    try {
      return window.localStorage.getItem(key)
    } catch {
      return null
    }
  }

  store(key, value) {
    try {
      window.localStorage.setItem(key, value)
    } catch {
      // Private browsing / disabled storage: keep the in-memory state only.
    }
  }
}
