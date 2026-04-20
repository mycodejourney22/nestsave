class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def index?  = false
  def show?   = false
  def create? = false
  def update? = false
  def destroy? = false

  private

  def current_membership
    @current_membership ||= user.active_membership_for(record.try(:company) || record)
  end

  def employee_or_above?
    current_membership.present?
  end

  def team_manager_or_above?
    current_membership&.team_manager_or_above?
  end

  def hr_or_above?
    current_membership&.hr_or_above?
  end

  def super_admin?
    current_membership&.super_admin?
  end

  def owns_record?
    record.try(:company_membership)&.user_id == user.id
  end
end
