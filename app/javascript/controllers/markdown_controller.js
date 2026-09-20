import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import DOMPurify from "dompurify"

// Renders the raw markdown text sitting in the "source" target (plain,
// Rails-escaped text content) as sanitized HTML in the "output" target.
export default class extends Controller {
  static targets = ["source", "output"]

  connect() {
    if (!this.hasSourceTarget || !this.hasOutputTarget) return

    const raw = this.sourceTarget.textContent.trim()
    if (!raw) return

    const html = marked.parse(raw, { breaks: true })
    this.outputTarget.innerHTML = DOMPurify.sanitize(html)
  }
}
