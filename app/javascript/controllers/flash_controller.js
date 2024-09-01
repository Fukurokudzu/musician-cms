import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="flash"
/* global bootstrap */
export default class extends Controller {
  connect () {
    const toast = document.getElementById('toast')
    const toastBootstrap = bootstrap.Toast.getOrCreateInstance(toast)
    toastBootstrap.show()
  }
}
