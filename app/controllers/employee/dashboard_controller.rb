module Employee
  class DashboardController < ApplicationController
    before_action :require_employee!

    def show
      @profile        = @current_membership.employee_profile
      @current_salary = @profile&.current_salary
      @current_team   = @profile&.team

      # Leave balances — build for all active annual leave types,
      # falling back to LeaveBalance.new for types with no DB record yet
      if @profile
        annual_types = @current_company.leave_types.active
                         .where(category: "annual").order(:name)
        existing     = @profile.leave_balances
                         .includes(:leave_type)
                         .where(year: Date.current.year)
                         .index_by(&:leave_type_id)
        @leave_balances = annual_types.map do |lt|
          existing[lt.id] || LeaveBalance.new(
            employee_profile: @profile,
            leave_type:       lt,
            year:             Date.current.year,
            total_days:       lt.default_days,
            accrued_days:     lt.default_days,
            used_days:        0,
            override_days:    0
          )
        end
      else
        @leave_balances = []
      end

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
