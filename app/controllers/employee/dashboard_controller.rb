module Employee
  class DashboardController < ApplicationController
    before_action :require_employee!

    def show
      @profile        = @current_membership.employee_profile
      @current_salary = @profile&.current_salary
      @current_team   = @profile&.team

      # Leave balances — annual only (shown on dashboard)
      @leave_balances = @profile&.leave_balances
                          .includes(:leave_type)
                          .where(year: Date.current.year)
                          .order(:created_at) || []

      # This week's published rota for the employee's team
      @current_rota = nil
      @my_entries   = []
      if @current_team
        @current_rota = @current_team.rotas
                          .published
                          .where("week_start <= ? AND week_end >= ?", Date.current, Date.current)
                          .includes(rota_entries: [])
                          .first
        if @current_rota
          @my_entries = @current_rota.rota_entries
                          .where(employee_profile: @profile)
                          .order(:work_date)
        end
      end

      # Savings & advances
      @active_plans = @current_membership.savings_plans
                        .kept.active.order(created_at: :desc)
      @open_advance = @current_membership.salary_advances
                        .kept
                        .where(status: %w[approved disbursed repaying])
                        .order(applied_at: :desc)
                        .first

      # Recent transactions
      @recent_transactions = @current_membership.transactions
                               .order(created_at: :desc)
                               .limit(5)
    end
  end
end
