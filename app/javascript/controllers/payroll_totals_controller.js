import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["earningsAmount", "deductionsAmount", "totalEarnings", "totalDeductions", "netPay", "earningsBody", "deductionsBody"]

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
      this.netPayTarget.classList.toggle("text-red-600",    net < 0)
      this.netPayTarget.classList.toggle("text-emerald-700", net >= 0)
    }
  }

  format(amount) {
    const symbol = this.element.dataset.currencySymbol || ""
    return symbol + Math.abs(amount).toLocaleString("en-GB", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }

  addEarningsRow(event) {
    event.preventDefault()
    const idx = Date.now()
    const row = document.createElement("tr")
    row.innerHTML = `
      <td class="px-5 py-3.5" colspan="2">
        <div class="flex items-center gap-2 flex-wrap">
          <input type="text"
                 name="new_bonuses[${idx}][label]"
                 placeholder="Description e.g. Target bonus Q1"
                 class="flex-1 min-w-0 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500">
          <select name="new_bonuses[${idx}][item_type]"
                  class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500">
            <option value="target_bonus">Target bonus</option>
            <option value="birthday_bonus">Birthday bonus</option>
            <option value="outdoor_stipend">Outdoor stipend</option>
            <option value="other_bonus">Other bonus</option>
          </select>
          <input type="number"
                 name="new_bonuses[${idx}][amount]"
                 placeholder="0.00"
                 step="0.01" min="0"
                 data-payroll-totals-target="earningsAmount"
                 data-action="input->payroll-totals#update"
                 class="w-32 text-right rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500">
          <button type="button"
                  data-action="click->payroll-totals#removeRow"
                  class="text-red-400 hover:text-red-600 text-lg font-bold px-2 leading-none">×</button>
        </div>
      </td>
      <td></td>
    `
    this.earningsBodyTarget.appendChild(row)
  }

  addDeductionsRow(event) {
    event.preventDefault()
    const idx = Date.now()
    const row = document.createElement("tr")
    row.innerHTML = `
      <td class="px-5 py-3.5" colspan="2">
        <div class="flex items-center gap-2 flex-wrap">
          <input type="text"
                 name="new_deductions[${idx}][label]"
                 placeholder="Description e.g. Uniform fine"
                 class="flex-1 min-w-0 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500">
          <select name="new_deductions[${idx}][item_type]"
                  class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500">
            <option value="fine">Fine</option>
            <option value="other_deduction">Other deduction</option>
          </select>
          <input type="number"
                 name="new_deductions[${idx}][amount]"
                 placeholder="0.00"
                 step="0.01" min="0"
                 data-payroll-totals-target="deductionsAmount"
                 data-action="input->payroll-totals#update"
                 class="w-32 text-right rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500">
          <button type="button"
                  data-action="click->payroll-totals#removeRow"
                  class="text-red-400 hover:text-red-600 text-lg font-bold px-2 leading-none">×</button>
        </div>
      </td>
      <td></td>
    `
    this.deductionsBodyTarget.appendChild(row)
  }

  removeRow(event) {
    event.preventDefault()
    event.target.closest("tr").remove()
    this.update()
  }
}
