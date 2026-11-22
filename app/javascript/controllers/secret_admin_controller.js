import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

const STORAGE_KEY = 'footer-secret-clicks'
const WINDOW_MS = 1000

// Hidden shortcut: three quick clicks on the site footer take the visitor to
// /admin. Clicks on links inside the footer (the contact link) behave as usual.
export default class extends Controller {
  click(event) {
    // Never hijack real links or buttons (e.g. the footer contact link).
    if (event.target.closest('a, button')) return

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
      Turbo.visit('/admin')
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
