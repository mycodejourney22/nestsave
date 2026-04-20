class EmergencyContact < ApplicationRecord
  belongs_to :employee_profile

  validates :full_name,    presence: true
  validates :relationship, presence: true
  validates :phone,        presence: true

  before_save :clear_other_primaries, if: -> { primary? && primary_changed? }

  private

  def clear_other_primaries
    employee_profile.emergency_contacts
                    .where.not(id: id)
                    .where(primary: true)
                    .update_all(primary: false)
  end
end
