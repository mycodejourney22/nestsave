class EmployeeProfilePolicy < ApplicationPolicy
  def index?  = hr_or_above?
  def show?   = owns_record? || hr_or_above?
  def edit?   = hr_or_above?
  def update? = hr_or_above?
end
