import { Controller } from "@hotwired/stimulus"

const CURRENCY_MAP = {
  "United Kingdom":       { currency: "GBP", currency_symbol: "£" },
  "United States":        { currency: "USD", currency_symbol: "$" },
  "Nigeria":              { currency: "NGN", currency_symbol: "₦" },
  "Kenya":                { currency: "KES", currency_symbol: "KSh" },
  "Ghana":                { currency: "GHS", currency_symbol: "GH₵" },
  "South Africa":         { currency: "ZAR", currency_symbol: "R" },
  "Canada":               { currency: "CAD", currency_symbol: "CA$" },
  "Australia":            { currency: "AUD", currency_symbol: "A$" },
  "Germany":              { currency: "EUR", currency_symbol: "€" },
  "France":               { currency: "EUR", currency_symbol: "€" },
  "Netherlands":          { currency: "EUR", currency_symbol: "€" },
  "Ireland":              { currency: "EUR", currency_symbol: "€" },
  "Spain":                { currency: "EUR", currency_symbol: "€" },
  "India":                { currency: "INR", currency_symbol: "₹" },
  "Singapore":            { currency: "SGD", currency_symbol: "S$" },
  "United Arab Emirates": { currency: "AED", currency_symbol: "د.إ" },
  "Rwanda":               { currency: "RWF", currency_symbol: "RF" },
  "Uganda":               { currency: "UGX", currency_symbol: "USh" },
  "Tanzania":             { currency: "TZS", currency_symbol: "TSh" },
  "Zambia":               { currency: "ZMW", currency_symbol: "ZK" },
}

export default class extends Controller {
  static targets = ["country", "currency", "currencySymbol", "currencyDisplay"]

  select() {
    const country = this.countryTarget.value
    const data    = CURRENCY_MAP[country]
    if (data) {
      this.currencyTarget.value       = data.currency
      this.currencySymbolTarget.value = data.currency_symbol
      if (this.hasCurrencyDisplayTarget) {
        this.currencyDisplayTarget.textContent = `${data.currency} (${data.currency_symbol})`
      }
    }
  }
}
