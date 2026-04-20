class EmployeeProfile < ApplicationRecord
  belongs_to :company_membership
  belongs_to :department, optional: true
  belongs_to :team, optional: true

  has_many :employment_histories, dependent: :destroy
  has_many :emergency_contacts,   dependent: :destroy
  has_many :salary_histories,     dependent: :destroy
  has_many :bank_details,         dependent: :destroy
  has_many :documents,            -> { kept }, dependent: :destroy
  has_many :employee_references,  dependent: :destroy
  has_many :leave_balances,       dependent: :destroy
  has_many :leave_requests,       dependent: :destroy
  has_many :rota_entries,         dependent: :destroy

  EMPLOYMENT_TYPES = %w[full_time part_time contractor].freeze

  enum :employment_type, {
    full_time:  "full_time",
    part_time:  "part_time",
    contractor: "contractor"
  }

  validates :employment_type,       presence: true, inclusion: { in: EMPLOYMENT_TYPES }
  validates :employment_start_date, presence: true
  validates :employee_number,       presence: true, uniqueness: true

  before_validation :generate_employee_number, on: :create

  delegate :user, :company, to: :company_membership

  def current_salary
    salary_histories.order(effective_date: :desc).first&.amount
  end

  def active_bank_detail
    bank_details.find_by(active: true)
  end

  def employment_type_label
    employment_type.humanize.gsub("_", " ")
  end

  def company_wide?
    team_id.nil?
  end

  private

  def generate_employee_number
    self.employee_number ||= "EMP-#{SecureRandom.random_number(9000) + 1000}"
  end
end
