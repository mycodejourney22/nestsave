class PayrollItem < ApplicationRecord
  belongs_to :payroll_entry

  CATEGORIES = %w[earning deduction].freeze
  ITEM_TYPES = %w[
    base_salary target_bonus birthday_bonus outdoor_stipend other_bonus
    paye pension savings advance_repayment fine other_deduction
  ].freeze

  EARNING_TYPES = %w[base_salary target_bonus birthday_bonus outdoor_stipend other_bonus].freeze
  DEDUCTION_TYPES = %w[paye pension savings advance_repayment fine other_deduction].freeze

  scope :editable, -> { where(editable: true) }

  validates :category, inclusion: { in: CATEGORIES }
  validates :item_type, inclusion: { in: ITEM_TYPES }
  validates :label, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  before_update :check_editable

  private

  def check_editable
    unless editable?
      raise ActiveRecord::ReadOnlyRecord, "This payroll item cannot be modified"
    end
  end
end
