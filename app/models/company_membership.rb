class CompanyMembership < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :company
  belongs_to :inviter, class_name: "User", foreign_key: :invited_by, optional: true

  has_one  :employee_profile,   dependent: :destroy
  has_many :savings_plans,       -> { kept }, dependent: :destroy
  has_many :salary_advances,     -> { kept }, dependent: :destroy
  has_many :withdrawal_requests, dependent: :destroy
  has_many :transactions,        dependent: :destroy

  ROLES    = %w[employee studio_manager hr_admin super_admin].freeze
  STATUSES = %w[active suspended left pending].freeze

  enum :role, {
    employee:       "employee",
    studio_manager: "studio_manager",
    hr_admin:       "hr_admin",
    super_admin:    "super_admin"
  }

  enum :status, { active: "active", suspended: "suspended", left: "left", pending: "pending" }

  validates :role,   inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: {
    scope: :company_id,
    conditions: -> { where(deleted_at: nil) },
    message: "is already a member of this company"
  }, if: -> { user_id.present? }

  scope :active,          -> { kept.where(status: "active") }
  scope :hr_admins,       -> { kept.where(role: "hr_admin") }
  scope :pending_invites, -> { kept.where(status: "pending") }
  scope :cancellable,     -> { kept.where(status: "pending") }

  delegate :current_salary, :job_title, :department, to: :employee_profile, allow_nil: true

  def hr_or_above?
    hr_admin? || super_admin?
  end

  def studio_manager_or_above?
    studio_manager? || hr_admin? || super_admin?
  end

  def can_access_hr?
    hr_or_above?
  end

  def can_access_payroll?
    hr_or_above?
  end

  def can_access_studio?
    studio_manager_or_above?
  end

  def can_manage_company?
    super_admin?
  end

  def cancellable?
    !deleted? && pending?
  end

  def display_name
    user&.full_name || invited_name || "—"
  end

  def display_email
    user&.email || invited_email || "—"
  end

  def display_initials
    display_name.split.first(2).map { |w| w[0].upcase }.join
  end

  def outstanding_advance_balance
    salary_advances.where(status: %w[approved disbursed repaying]).sum(:amount)
  end

  def has_active_advance?
    salary_advances.where(status: %w[pending approved disbursed repaying]).exists?
  end
end
