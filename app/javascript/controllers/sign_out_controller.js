import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
  perform(event) {
    event.preventDefault()

    const header = this.element.closest('.admin-header')
    if (header) header.hidden = true

    fetch(this.element.href, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
      }
    })
      .catch(() => {})
      .finally(() => { Turbo.visit('/') })
  }
}
