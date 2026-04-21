import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["earningsAmount", "deductionsAmount", "totalEarnings", "totalDeductions", "netPay"]

  connect() {
    this.update()
  }

  update() {
    const earnings = this.earningsAmountTargets.reduce((sum, el) => {
      return sum + (parseFloat(el.value.replace(/,/g, "")) || 0)
    }, 0)

    const deductions = this.deductionsAmountTargets.reduce((sum, el) => {
      return sum + (parseFloat(el.value.replace(/,/g, "")) || 0)
    }, 0)

    const net = earnings - deductions

    if (this.hasTotalEarningsTarget)   this.totalEarningsTarget.textContent   = this.format(earnings)
    if (this.hasTotalDeductionsTarget) this.totalDeductionsTarget.textContent = this.format(deductions)
    if (this.hasNetPayTarget) {
      this.netPayTarget.textContent = this.format(net)
      this.netPayTarget.classList.toggle("text-red-600", net < 0)
      this.netPayTarget.classList.toggle("text-emerald-700", net >= 0)
    }
  }

  format(amount) {
    const symbol = this.element.dataset.currencySymbol || "£"
    return symbol + Math.abs(amount).toLocaleString("en-GB", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  addEarningsRow(event) {
    event.preventDefault()
    const template = this.element.querySelector("#earnings-row-template")
    const clone = template.content.cloneNode(true)
    const idx = Date.now()
    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("__idx__", idx)
    })
    template.parentElement.insertBefore(clone, template)
  }

  addDeductionsRow(event) {
    event.preventDefault()
    const template = this.element.querySelector("#deductions-row-template")
    const clone = template.content.cloneNode(true)
    const idx = Date.now()
    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("__idx__", idx)
    })
    template.parentElement.insertBefore(clone, template)
  }

  removeRow(event) {
    event.preventDefault()
    event.target.closest("tr").remove()
    this.update()
  }
}
