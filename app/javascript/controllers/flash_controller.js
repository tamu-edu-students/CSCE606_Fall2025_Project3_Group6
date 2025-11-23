import { Controller } from "@hotwired/stimulus"

// Simple dismiss controller for flash messages.
export default class extends Controller {
  dismiss(event) {
    event.preventDefault()
    this.element.closest("[role='alert']")?.remove()
  }
}
