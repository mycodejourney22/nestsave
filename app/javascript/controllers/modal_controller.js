import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["wrapper"]

  connect() {
    // Listen for turbo-frame load inside the modal turbo-frame
    this.frameLoadHandler = () => this.open()
    document.getElementById("modal")?.addEventListener("turbo:frame-load", this.frameLoadHandler)
  }

  disconnect() {
    document.getElementById("modal")?.removeEventListener("turbo:frame-load", this.frameLoadHandler)
  }

  open() {
    this.wrapperTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.wrapperTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    // Clear the turbo-frame so it doesn't flash on next open
    const frame = document.getElementById("modal")
    if (frame) frame.innerHTML = ""
  }
}
