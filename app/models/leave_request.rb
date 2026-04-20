class LeaveRequest < ApplicationRecord
  belongs_to :employee_profile
  belongs_to :leave_type
  belongs_to :leave_balance, optional: true
  belongs_to :reviewer, class_name: "User",
             foreign_key: :reviewed_by, optional: true

  STATUSES = %w[pending approved declined cancelled].freeze

  enum :status, {
    pending:   "pending",
    approved:  "approved",
    declined:  "declined",
    cancelled: "cancelled"
  }

  validates :start_date, :end_date, :total_days, presence: true
  validate  :end_date_after_start_date
  validate  :sufficient_balance, if: :requires_balance?
  validate  :no_overlapping_requests

  before_validation { self.requested_at ||= Time.current }
  before_validation :calculate_total_days

  delegate :user,    to: :employee_profile
  delegate :company, to: :employee_profile

  private

  def calculate_total_days
    return unless start_date && end_date
    days = (start_date..end_date).count { |d| !d.saturday? && !d.sunday? }
    self.total_days = days
  end

  def requires_balance?
    leave_type&.requires_balance?
  end

  def sufficient_balance
    return unless leave_balance && total_days
    if total_days > leave_balance.remaining_days
      errors.add(:base,
        "Insufficient leave balance. You have #{leave_balance.remaining_days} days remaining.")
    end
  end

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def no_overlapping_requests
    return unless start_date && end_date
    overlapping = employee_profile.leave_requests
      .where(status: %w[pending approved])
      .where.not(id: id)
      .where("start_date <= ? AND end_date >= ?", end_date, start_date)
    errors.add(:base, "You already have a leave request for this period") if overlapping.exists?
  end
end
