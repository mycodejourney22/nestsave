module Admin
  class DashboardController < ApplicationController
    include Admin::PendingActionsConcern

    before_action :require_hr!

    def show
      @pending_actions = build_pending_actions
      @monthly_summary = monthly_summary
      @recent_activity = recent_activity
    end

    private

    def monthly_summary
      membership_ids = @current_company.company_memberships.active.pluck(:id)
      period         = Date.current.beginning_of_month

      {
        savings_total:      Transaction.where(company_membership_id: membership_ids, kind: :savings_deduction, period_month: period).sum(:amount),
        advance_repayments: Transaction.where(company_membership_id: membership_ids, kind: :advance_repayment, period_month: period).sum(:amount),
        active_savers:      SavingsPlan.where(company_membership_id: membership_ids, status: :active).count,
        active_advances:    SalaryAdvance.where(company_membership_id: membership_ids, status: %w[disbursed repaying]).count,
        headcount:          membership_ids.size,
        pending_invites:    @current_company.company_memberships.kept.pending_invites.count
      }
    end

    def recent_activity
      membership_ids = @current_company.company_memberships.active.pluck(:id)
      Transaction
        .where(company_membership_id: membership_ids)
        .includes(:company_membership)
        .order(created_at: :desc)
        .limit(8)
    end
  end
end
