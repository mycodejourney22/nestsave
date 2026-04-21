class PayrollEntry < ApplicationRecord
  belongs_to :payroll_run
  belongs_to :employee_profile

  has_many :payroll_items, dependent: :destroy

  delegate :company_membership, to: :employee_profile
  delegate :display_name,       to: :company_membership
  delegate :company,            to: :payroll_run

  def earnings_items
    payroll_items.where(category: "earning").order(:auto_generated, :created_at)
  end

  def deductions_items
    payroll_items.where(category: "deduction").order(:auto_generated, :created_at)
  end

  def recalculate!
    self.total_earnings   = payroll_items.where(category: "earning").sum(:amount)
    self.total_deductions = payroll_items.where(category: "deduction").sum(:amount)
    self.net_pay          = total_earnings - total_deductions
    save!
  end

  def editable?
    payroll_run.editable? && !locked?
  end
end
