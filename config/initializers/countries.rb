COUNTRIES_WITH_CURRENCY = [
  { country: "United Kingdom",      currency: "GBP", currency_symbol: "£" },
  { country: "United States",       currency: "USD", currency_symbol: "$" },
  { country: "Nigeria",             currency: "NGN", currency_symbol: "₦" },
  { country: "Kenya",               currency: "KES", currency_symbol: "KSh" },
  { country: "Ghana",               currency: "GHS", currency_symbol: "GH₵" },
  { country: "South Africa",        currency: "ZAR", currency_symbol: "R" },
  { country: "Canada",              currency: "CAD", currency_symbol: "CA$" },
  { country: "Australia",           currency: "AUD", currency_symbol: "A$" },
  { country: "Germany",             currency: "EUR", currency_symbol: "€" },
  { country: "France",              currency: "EUR", currency_symbol: "€" },
  { country: "Netherlands",         currency: "EUR", currency_symbol: "€" },
  { country: "Ireland",             currency: "EUR", currency_symbol: "€" },
  { country: "Spain",               currency: "EUR", currency_symbol: "€" },
  { country: "India",               currency: "INR", currency_symbol: "₹" },
  { country: "Singapore",           currency: "SGD", currency_symbol: "S$" },
  { country: "United Arab Emirates",currency: "AED", currency_symbol: "د.إ" },
  { country: "Rwanda",              currency: "RWF", currency_symbol: "RF" },
  { country: "Uganda",              currency: "UGX", currency_symbol: "USh" },
  { country: "Tanzania",            currency: "TZS", currency_symbol: "TSh" },
  { country: "Zambia",              currency: "ZMW", currency_symbol: "ZK"  },
].freeze

COUNTRY_CURRENCY_MAP = COUNTRIES_WITH_CURRENCY.each_with_object({}) do |entry, hash|
  hash[entry[:country]] = { currency: entry[:currency], currency_symbol: entry[:currency_symbol] }
end.freeze
