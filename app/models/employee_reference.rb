class EmployeeReference < ApplicationRecord
  belongs_to :employee_profile

  STATUSES = %w[not_requested requested received waived].freeze

  enum :status, {
    not_requested: "not_requested",
    requested:     "requested",
    received:      "received",
    waived:        "waived"
  }

  validates :referee_name,  presence: true
  validates :relationship,  presence: true
  validates :status,        inclusion: { in: STATUSES }
end
