import { Controller } from '@hotwired/stimulus'

const STORAGE_KEY = 'title-secret-clicks'
const WINDOW_MS = 1000

// Hidden shortcut: three quick clicks on the site title take the visitor to
// /admin. Normal clicks behave as usual (Turbo navigation to /).
export default class extends Controller {
  click(event) {
    const now = Date.now()
    const state = this.read()

    if (!state || now - state.time > WINDOW_MS) {
      this.store({ count: 1, time: now })
      return
    }

    const count = state.count + 1
    if (count >= 3) {
      event.preventDefault()
      window.sessionStorage.removeItem(STORAGE_KEY)
      window.location.assign('/admin')
      return
    }
    this.store({ count, time: now })
  }

  read() {
    try {
      return JSON.parse(window.sessionStorage.getItem(STORAGE_KEY))
    } catch {
      return null
    }
  }

  store(state) {
    try {
      window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(state))
    } catch {
      // sessionStorage may be unavailable (private mode) — the shortcut just won't trigger
    }
  }
}
