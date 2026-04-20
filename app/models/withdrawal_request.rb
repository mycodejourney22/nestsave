class WithdrawalRequest < ApplicationRecord
  belongs_to :savings_plan
  belongs_to :company_membership
  belongs_to :reviewer, class_name: "User", foreign_key: :reviewed_by, optional: true

  STATUSES = %w[pending approved declined processed].freeze

  enum :status, {
    pending:   "pending",
    approved:  "approved",
    declined:  "declined",
    processed: "processed"
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate  :amount_does_not_exceed_saved_balance
  validate  :savings_plan_is_active_or_matured

  before_validation { self.requested_at ||= Time.current }

  delegate :user, :company, to: :company_membership

  private

  def amount_does_not_exceed_saved_balance
    return unless savings_plan && amount
    if amount > savings_plan.total_saved
      errors.add(:amount, "cannot exceed total saved balance of #{savings_plan.total_saved}")
    end
  end

  def savings_plan_is_active_or_matured
    return unless savings_plan
    unless savings_plan.active? || savings_plan.matured?
      errors.add(:base, "withdrawals can only be made from active or matured plans")
    end
  end
end
