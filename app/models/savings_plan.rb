class SavingsPlan < ApplicationRecord
  belongs_to :company_membership
  belongs_to :approver, class_name: "User", foreign_key: :approved_by, optional: true

  has_many :withdrawal_requests, dependent: :destroy
  has_many :transactions, as: :reference, dependent: :nullify

  STATUSES = %w[pending active matured closed declined].freeze

  enum :status, {
    pending:  "pending",
    active:   "active",
    matured:  "matured",
    closed:   "closed",
    declined: "declined"
  }

  validates :name,            presence: true
  validates :monthly_amount,  presence: true, numericality: { greater_than: 0 }
  validates :duration_months, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 60 }
  validates :start_date,      presence: true
  validates :maturity_date,   presence: true
  validate  :maturity_date_after_start_date

  before_validation :compute_maturity_date, if: -> { start_date.present? && duration_months.present? }

  scope :active,   -> { kept.where(status: "active") }
  scope :pending,  -> { kept.where(status: "pending") }
  scope :matured,  -> { kept.where(status: "matured") }

  delegate :user, :company, to: :company_membership

  def target_amount
    monthly_amount * duration_months
  end

  def progress_percentage
    return 0 if target_amount.zero?
    [(total_saved / target_amount * 100).round(1), 100].min
  end

  def months_remaining
    return 0 unless active?
    ((maturity_date - Date.current) / 30).ceil
  end

  def mature!
    update!(status: :matured)
  end

  private

  def compute_maturity_date
    self.maturity_date = start_date + duration_months.months
  end

  def maturity_date_after_start_date
    return unless start_date && maturity_date
    errors.add(:maturity_date, "must be after start date") if maturity_date <= start_date
  end
end
