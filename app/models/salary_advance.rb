class SalaryAdvance < ApplicationRecord
  belongs_to :company_membership
  belongs_to :reviewer, class_name: "User", foreign_key: :reviewed_by, optional: true

  has_many :advance_repayment_schedules, dependent: :destroy
  has_many :transactions, as: :reference, dependent: :nullify

  STATUSES = %w[pending approved disbursed repaying settled declined].freeze

  enum :status, {
    pending:   "pending",
    approved:  "approved",
    disbursed: "disbursed",
    repaying:  "repaying",
    settled:   "settled",
    declined:  "declined"
  }

  validates :amount,           presence: true, numericality: { greater_than: 0 }
  validates :reason,           presence: true
  validates :repayment_months, presence: true, numericality: { only_integer: true, in: 1..6 }
  validate  :amount_does_not_exceed_salary
  validate  :no_existing_open_advance

  before_validation { self.applied_at ||= Time.current }
  before_validation :compute_monthly_instalment

  delegate :user, :company, to: :company_membership

  def amount_repaid
    advance_repayment_schedules.where(status: :paid).sum(:amount)
  end

  def amount_outstanding
    amount - amount_repaid
  end

  def fully_repaid?
    advance_repayment_schedules.where(status: :pending).none?
  end

  private

  def compute_monthly_instalment
    return unless amount.present? && repayment_months.present? && repayment_months > 0
    self.monthly_instalment = (amount / repayment_months).round(2)
  end

  def amount_does_not_exceed_salary
    return unless company_membership && amount
    salary = company_membership.current_salary
    if salary.nil?
      errors.add(:base, "your employment profile has not been set up yet — please contact your payroll admin")
      return
    end
    if amount > salary
      errors.add(:amount, "cannot exceed your monthly salary of #{salary}")
    end
  end

  def no_existing_open_advance
    return unless company_membership
    open_statuses = %w[pending approved disbursed repaying]
    scope = company_membership.salary_advances.where(status: open_statuses)
    scope = scope.where.not(id: id) if persisted?
    if scope.exists?
      errors.add(:base, "you already have an open salary advance. Please settle it before applying for another.")
    end
  end
end
