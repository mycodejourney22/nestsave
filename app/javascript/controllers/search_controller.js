import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list"]

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    const rows  = this.listTarget.querySelectorAll("[data-search-row]")

    rows.forEach(row => {
      const name  = row.dataset.name  || ""
      const title = row.dataset.title || ""
      const dept  = row.dataset.dept  || ""
      const match = !query || name.includes(query) || title.includes(query) || dept.includes(query)
      row.style.display = match ? "" : "none"
    })
  }
}
