module MailerHelper
  def initials(name)
    name.to_s.split.first(2).map { |n| n[0].upcase }.join
  end

  def formatted_currency(amount)
    symbol = defined?(@company) && @company&.currency_symbol.presence || "£"
    "#{symbol}#{'%.2f' % amount.to_f}"
  end

  def formatted_date(date)
    date&.strftime("%-d %B %Y")
  end

  def formatted_month(date)
    date&.strftime("%B %Y")
  end
end
