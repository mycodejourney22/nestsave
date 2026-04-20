class SalaryHistory < ApplicationRecord
  belongs_to :employee_profile
  belongs_to :recorder, class_name: "User", foreign_key: :changed_by

  validates :amount,         presence: true, numericality: { greater_than: 0 }
  validates :effective_date, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord, "Salary histories are immutable" }

  scope :chronological, -> { order(effective_date: :asc) }
end
