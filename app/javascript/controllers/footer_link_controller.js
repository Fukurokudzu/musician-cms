import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['type', 'emailSection', 'urlSection']

  connect() {
    this.toggle()
  }

  toggle() {
    const isEmail = this.typeTarget.value === 'email'
    this.emailSectionTarget.hidden = !isEmail
    this.urlSectionTarget.hidden = isEmail
  }
}
