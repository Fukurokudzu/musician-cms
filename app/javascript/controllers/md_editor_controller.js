import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    // Remove leftovers from a cached snapshot: SimpleMDE has no official
    // destroy, so re-initializing on a restored DOM needs a cleanup first.
    const parent = this.element.parentElement
    parent.querySelector('.CodeMirror')?.remove()
    parent.querySelector('.editor-toolbar')?.remove()

    this.editor = new SimpleMDE({ element: this.element })
  }
}
