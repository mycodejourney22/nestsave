class Company < ApplicationRecord
  has_many :company_memberships, -> { kept }, dependent: :destroy
  has_many :users, through: :company_memberships
  has_many :departments,  -> { kept }, dependent: :destroy
  has_many :teams,        -> { kept }, dependent: :destroy
  has_many :leave_types,  dependent: :destroy
  has_many :payroll_runs, dependent: :destroy

  validates :name,          presence: true
  validates :slug,          presence: true, uniqueness: true,
                            format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers and hyphens" }
  validates :payroll_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :payroll_day,   presence: true, numericality: { only_integer: true, in: 1..28 }
  validates :timezone,      presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :active, -> { kept.where(active: true) }

  def hr_admins
    company_memberships.hr_admins.includes(:user).map(&:user)
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
  end
end
