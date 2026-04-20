class LeaveType < ApplicationRecord
  belongs_to :company
  has_many :leave_balances, dependent: :destroy
  has_many :leave_requests, dependent: :destroy

  CATEGORIES = %w[annual sick maternity other].freeze

  enum :category, {
    annual:    "annual",
    sick:      "sick",
    maternity: "maternity",
    other:     "other"
  }

  validates :name, presence: true,
            uniqueness: { scope: :company_id, case_sensitive: false }
  validates :category, inclusion: { in: CATEGORIES }

  scope :active,        -> { where(active: true) }
  scope :with_balance,  -> { where(requires_balance: true) }
end
