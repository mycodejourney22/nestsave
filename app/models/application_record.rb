class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Soft delete support — models that include this scope
  # will automatically exclude deleted records
  scope :kept,    -> { where(deleted_at: nil) }
  scope :trashed, -> { where.not(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def restore!
    update!(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
end
