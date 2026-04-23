import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    event.stopPropagation()
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  // Close when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.panelTarget.classList.add("hidden")
    }
  }

  connect() {
    this._outsideClick = this.clickOutside.bind(this)
    document.addEventListener("click", this._outsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
  }
}
