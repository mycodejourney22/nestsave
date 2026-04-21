class PayrollRun < ApplicationRecord
  belongs_to :company
  belongs_to :creator,   class_name: "User", foreign_key: :created_by
  belongs_to :finaliser, class_name: "User", foreign_key: :finalised_by, optional: true

  has_many :payroll_entries, dependent: :destroy

  STATUSES = %w[draft in_review finalised payslips_sent].freeze

  enum :status, {
    draft:         "draft",
    in_review:     "in_review",
    finalised:     "finalised",
    payslips_sent: "payslips_sent"
  }

  validates :month, :year, presence: true
  validates :month, uniqueness: { scope: [:company_id, :year],
                                  message: "payroll run already exists for this month" }
  validates :month, inclusion: { in: 1..12 }

  scope :recent, -> { order(year: :desc, month: :desc) }

  def period_label
    Date.new(year, month, 1).strftime("%B %Y")
  end

  def editable?
    !payslips_sent?
  end

  def total_gross
    payroll_entries.sum(:total_earnings)
  end

  def total_deductions
    payroll_entries.sum(:total_deductions)
  end

  def total_net
    payroll_entries.sum(:net_pay)
  end

  def recalculate_totals!
    payroll_entries.each(&:recalculate!)
  end
end
