class BankDetail < ApplicationRecord
  belongs_to :employee_profile
  belongs_to :recorder, class_name: "User", foreign_key: :recorded_by

  validates :bank_name,      presence: true
  validates :account_name,   presence: true
  validates :account_number, presence: true
  validates :sort_code,      presence: true

  before_create :deactivate_previous
  before_update { raise ActiveRecord::ReadOnlyRecord, "Bank details are immutable — create a new record instead" }

  scope :active, -> { where(active: true) }

  private

  def deactivate_previous
    employee_profile.bank_details.where(active: true).update_all(active: false)
  end
end
