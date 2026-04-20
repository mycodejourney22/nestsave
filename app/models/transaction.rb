class Transaction < ApplicationRecord
  belongs_to :company_membership
  belongs_to :reference, polymorphic: true

  KINDS = %w[
    savings_deduction
    savings_withdrawal
    advance_disbursement
    advance_repayment
  ].freeze

  STATUSES = %w[pending completed failed].freeze

  enum :kind, {
    savings_deduction:    "savings_deduction",
    savings_withdrawal:   "savings_withdrawal",
    advance_disbursement: "advance_disbursement",
    advance_repayment:    "advance_repayment"
  }

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }

  validates :kind,         inclusion: { in: KINDS }
  validates :amount,       presence: true, numericality: { greater_than: 0 }
  validates :period_month, presence: true

  # Transactions are immutable — prevent updates
  before_update { raise ActiveRecord::ReadOnlyRecord, "Transactions cannot be modified" }

  scope :for_period, ->(date) { where(period_month: date.beginning_of_month) }
  scope :this_month, -> { for_period(Date.current) }

  delegate :user, :company, to: :company_membership
end
