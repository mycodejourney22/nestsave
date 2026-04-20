module ApplicationHelper
  include Pagy::Frontend

  STATUS_COLORS = {
    "pending"   => "bg-amber-50 text-amber-700 ring-amber-600/20",
    "active"    => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
    "approved"  => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
    "declined"  => "bg-red-50 text-red-700 ring-red-600/20",
    "matured"   => "bg-blue-50 text-blue-700 ring-blue-600/20",
    "closed"    => "bg-gray-100 text-gray-600 ring-gray-500/20",
    "disbursed" => "bg-teal-50 text-teal-700 ring-teal-600/20",
    "repaying"  => "bg-indigo-50 text-indigo-700 ring-indigo-600/20",
    "settled"   => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
    "processed" => "bg-blue-50 text-blue-700 ring-blue-600/20",
    "completed" => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
    "failed"    => "bg-red-50 text-red-700 ring-red-600/20",
    "suspended" => "bg-orange-50 text-orange-700 ring-orange-600/20",
    "left"      => "bg-gray-100 text-gray-600 ring-gray-500/20",
    "paid"      => "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
    "skipped"   => "bg-gray-100 text-gray-600 ring-gray-500/20",
  }.freeze

  def status_badge(status)
    css = STATUS_COLORS.fetch(status.to_s, "bg-gray-100 text-gray-600 ring-gray-500/20")
    content_tag(:span, status.to_s.humanize,
      class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset #{css}")
  end

  def currency_symbol
    @current_company&.currency_symbol.presence || "£"
  end

  def format_money(amount)
    number_to_currency(amount || 0, unit: currency_symbol, precision: 2, delimiter: ",")
  end

  # Kept as an alias so existing views continue to work.
  # Uses the company's configured currency symbol.
  def gbp(amount)
    format_money(amount)
  end

  def nav_link_class(path)
    active = request.path.start_with?(path)
    if active
      "flex items-center gap-2 mx-2 px-3 py-2 text-sm text-white bg-[#1D9E75] rounded-md"
    else
      "flex items-center gap-2 px-4 py-2 text-sm text-[#8aaa95] hover:text-white hover:bg-[#1a2e20] transition-colors"
    end
  end

  def kind_label(kind)
    {
      "savings_deduction"    => "Savings deducted",
      "savings_withdrawal"   => "Savings withdrawn",
      "advance_disbursement" => "Advance disbursed",
      "advance_repayment"    => "Advance repayment",
    }.fetch(kind.to_s, kind.to_s.humanize)
  end

  def kind_sign(kind)
    %w[savings_withdrawal advance_disbursement].include?(kind.to_s) ? "-" : "+"
  end

  def kind_color(kind)
    %w[savings_withdrawal advance_disbursement].include?(kind.to_s) ? "text-red-600" : "text-emerald-600"
  end
end
