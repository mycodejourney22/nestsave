module Admin
  class DashboardController < ApplicationController
    include Admin::PendingActionsConcern

    before_action :require_hr!

    def show
      # Hero stats
      @total_employees = @current_company.company_memberships.active.count
      @on_leave_today  = LeaveRequest
                           .joins(employee_profile: :company_membership)
                           .where(company_memberships: {
                             company_id: @current_company.id,
                             status: "active"
                           })
                           .where(status: "approved")
                           .where("start_date <= ? AND end_date >= ?", Date.current, Date.current)
                           .count
      @pending_actions = build_pending_actions
      @pending_count   = @pending_actions.count
      @pending_invites = @current_company.company_memberships
                           .where(status: "pending")
                           .where(invitation_accepted_at: nil)
                           .count

      # Teams overview
      @teams_overview = @current_company.teams.active
                          .includes(:employee_profiles)
                          .order(:name)
                          .map do |team|
        current_rota = team.rotas
                           .where("week_start <= ? AND week_end >= ?", Date.current, Date.current)
                           .first
        on_leave = LeaveRequest
                     .joins(:employee_profile)
                     .where(employee_profiles: { team_id: team.id })
                     .where(status: "approved")
                     .where("start_date <= ? AND end_date >= ?", Date.current, Date.current)
                     .count
        {
          team:         team,
          member_count: team.employee_profiles.where(deleted_at: nil).count,
          on_leave:     on_leave,
          rota_status:  current_rota&.status || "none"
        }
      end

      # Financial snapshot
      period         = Date.current.beginning_of_month
      membership_ids = @current_company.company_memberships.active.pluck(:id)
      @financial = {
        savings_deductions: Transaction
                              .where(company_membership_id: membership_ids,
                                     kind: "savings_deduction",
                                     period_month: period)
                              .sum(:amount),
        advance_repayments: Transaction
                              .where(company_membership_id: membership_ids,
                                     kind: "advance_repayment",
                                     period_month: period)
                              .sum(:amount),
        active_savers:      SavingsPlan
                              .where(company_membership_id: membership_ids,
                                     status: "active")
                              .count
      }
    end
  end
end
