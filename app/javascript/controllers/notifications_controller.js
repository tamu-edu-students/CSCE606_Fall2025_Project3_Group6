import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    event.preventDefault()
    this.panelTarget.classList.toggle('hidden')
  }

  // Close when clicking outside
  connect() {
    this._onDocClick = this._onDocClick.bind(this)
    document.addEventListener('click', this._onDocClick)
  }

  disconnect() {
    document.removeEventListener('click', this._onDocClick)
  }

  _onDocClick(e) {
    if (!this.element.contains(e.target)) {
      this.panelTarget.classList.add('hidden')
    }
  }
}
