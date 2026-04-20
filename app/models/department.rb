class Department < ApplicationRecord
  belongs_to :company
  has_many   :employee_profiles, dependent: :nullify

  validates :name, presence: true, uniqueness: {
    scope:      :company_id,
    conditions: -> { where(deleted_at: nil) },
    message:    "already exists in this company"
  }

  scope :active, -> { kept.where(active: true) }

  def to_s
    name
  end
end
