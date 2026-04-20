class SalaryAdvancePolicy < ApplicationPolicy
  def index?    = employee_or_above?
  def show?     = owns_record? || hr_or_above?
  def create?   = employee_or_above?
  def approve?  = hr_or_above?
  def decline?  = hr_or_above?
  def disburse? = hr_or_above?
end
