class EmploymentHistory < ApplicationRecord
  belongs_to :employee_profile

  validates :company_name, :job_title, :start_date, presence: true
  validate  :end_date_after_start_date

  scope :ordered, -> { order(start_date: :desc) }

  def current?
    end_date.nil?
  end

  def duration
    finish = end_date || Date.current
    months = ((finish - start_date) / 30).round
    return "#{months} month#{"s" if months != 1}" if months < 12
    years = (months / 12.0).round(1)
    "#{years} year#{"s" if years != 1}"
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end
end
