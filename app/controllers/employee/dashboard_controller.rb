module Employee
  class DashboardController < ApplicationController
    before_action :require_employee!

    def show
      @profile             = @current_membership.employee_profile
      @current_salary      = @profile&.current_salary
      @active_plans        = @current_membership.savings_plans.kept
                                                .where(status: :active)
                                                .order(start_date: :asc)
      @pending_plans       = @current_membership.savings_plans.kept
                                                .where(status: :pending)
                                                .order(created_at: :desc)
      @open_advance        = @current_membership.salary_advances.kept
                                                .where(status: %w[approved disbursed repaying])
                                                .order(applied_at: :desc)
                                                .first
      @recent_transactions = @current_membership.transactions.order(created_at: :desc).limit(5)
      @notifications       = current_user.notifications.unread.order(created_at: :desc).limit(5)
    end
  end
end
