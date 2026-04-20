class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  has_many :company_memberships, -> { kept }, dependent: :destroy
  has_many :companies, through: :company_memberships
  has_many :notifications, dependent: :destroy

  has_many :approved_savings_plans,   class_name: "SavingsPlan",       foreign_key: :approved_by
  has_many :reviewed_withdrawals,     class_name: "WithdrawalRequest",  foreign_key: :reviewed_by
  has_many :reviewed_advances,        class_name: "SalaryAdvance",      foreign_key: :reviewed_by

  validates :full_name, presence: true

  scope :kept, -> { where(deleted_at: nil) }

  def active_membership_for(company)
    company_memberships.active.find_by(company: company)
  end

  def employee_at?(company)
    company_memberships.active.employee.exists?(company: company)
  end

  def admin_at?(company)
    company_memberships.active.find_by(company: company)&.hr_or_above? || false
  end

  def unread_notifications_count
    notifications.unread.count
  end
end
