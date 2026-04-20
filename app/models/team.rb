class Team < ApplicationRecord
  belongs_to :company
  has_many :employee_profiles,  dependent: :nullify
  has_many :company_memberships, dependent: :nullify
  has_many :rotas, dependent: :destroy

  validates :name, presence: true,
            uniqueness: { scope: :company_id, case_sensitive: false }

  scope :kept,   -> { where(deleted_at: nil) }
  scope :active, -> { kept.where(active: true) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def manager
    company.company_memberships
           .active
           .team_manager
           .find_by(team_id: id)
           &.user
  end
end
