class CompanyPolicy < ApplicationPolicy
  def show?    = employee_or_above?
  def update?  = super_admin?
  def destroy? = super_admin?
end
