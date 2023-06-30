import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bs-tabs"
export default class extends Controller {
  connect() {
    var triggerTabList = [].slice.call(document.querySelectorAll('#tabs ul li a'))
    triggerTabList.forEach(function (triggerEl) {
      var tabTrigger = new bootstrap.Tab(triggerEl)

      triggerEl.addEventListener('click', function (event) {
        tabTrigger.show()
      })
    })
  }
}
