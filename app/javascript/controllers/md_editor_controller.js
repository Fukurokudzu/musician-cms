import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    // Remove leftovers from a cached snapshot: EasyMDE has no official
    // destroy, so re-initializing on a restored DOM needs a cleanup first.
    const parent = this.element.parentElement
    parent.querySelector('.CodeMirror')?.remove()
    parent.querySelector('.editor-toolbar')?.remove()

    // EasyMDE is the maintained drop-in fork of SimpleMDE and adds image
    // upload (toolbar button, paste, drag&drop) via imageUploadFunction.
    const EasyMDEClass = window.EasyMDE || window.SimpleMDE
    this.editor = new EasyMDEClass({
      element: this.element,
      uploadImage: true,
      imageUploadFunction: (file, onSuccess, onError) => this.uploadImage(file, onSuccess, onError)
    })
  }

  uploadImage(file, onSuccess, onError) {
    const body = new FormData()
    body.append('file', file)

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.uploadUrl, {
      method: 'POST',
      headers: token ? { 'X-CSRF-Token': token } : {},
      credentials: 'same-origin',
      body
    })
      .then(async (response) => {
        const json = await response.json().catch(() => ({}))
        if (!response.ok) throw new Error(json.error || `Upload failed (${response.status})`)

        onSuccess(json.url)
      })
      .catch((error) => onError(error.message))
  }

  get uploadUrl() {
    return this.element.dataset.uploadUrl || '/admin/uploads'
  }
}
