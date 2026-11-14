import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = this.hasSourceTarget ? this.sourceTarget.textContent : this.element.dataset.clipboardText
    if (!text) return

    try {
      await navigator.clipboard.writeText(text)
      this.copied()
    } catch (_error) {
      this.fallbackCopy(text)
    }
  }

  fallbackCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.style.position = "absolute"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()
    try {
      document.execCommand("copy")
      this.copied()
    } finally {
      document.body.removeChild(textarea)
    }
  }

  copied() {
    if (!this.hasButtonTarget) return
    const original = this.buttonTarget.innerHTML
    this.buttonTarget.innerHTML = '<i class="fas fa-check" aria-hidden="true"></i>'
    this.buttonTarget.classList.add("is-copied")
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.buttonTarget.innerHTML = original
      this.buttonTarget.classList.remove("is-copied")
    }, 1500)
  }
}
