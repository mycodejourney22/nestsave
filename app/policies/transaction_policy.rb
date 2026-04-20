class TransactionPolicy < ApplicationPolicy
  def index? = owns_record? || hr_or_above?
  def show?  = owns_record? || hr_or_above?
end
