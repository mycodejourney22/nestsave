import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "output"]

  generate() {
    const slug = this.sourceTarget.value
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
    this.outputTarget.value = slug
  }
}
