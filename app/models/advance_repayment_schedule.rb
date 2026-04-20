class AdvanceRepaymentSchedule < ApplicationRecord
  belongs_to :salary_advance

  STATUSES = %w[pending paid skipped].freeze

  enum :status, { pending: "pending", paid: "paid", skipped: "skipped" }

  validates :instalment_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :amount,            presence: true, numericality: { greater_than: 0 }
  validates :due_date,          presence: true

  scope :due_this_month, -> { where(due_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :overdue,        -> { pending.where("due_date < ?", Date.current.beginning_of_month) }
end
