class LeaveBalance < ApplicationRecord
  belongs_to :employee_profile
  belongs_to :leave_type
  belongs_to :overrider, class_name: "User",
             foreign_key: :overridden_by, optional: true

  has_many :leave_requests, dependent: :nullify

  validates :year, presence: true,
            uniqueness: { scope: [:employee_profile_id, :leave_type_id] }

  before_update :log_override, if: :override_days_changed?

  def remaining_days
    (accrued_days + override_days - used_days).round(1)
  end

  def accrue_month!
    return unless leave_type.accrues_monthly?
    monthly = (leave_type.default_days / 12.0).round(2)
    increment!(:accrued_days, monthly)
  end

  def self.for_employee_this_year(profile)
    where(employee_profile: profile, year: Date.current.year)
  end

  private

  def log_override
    self.overridden_at = Time.current
  end
end
