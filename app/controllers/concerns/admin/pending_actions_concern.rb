module Admin
  module PendingActionsConcern
    extend ActiveSupport::Concern

    def build_pending_actions
      actions = []

      pending_advances.each do |adv|
        actions << {
          type:          "advance",
          record:        adv,
          employee_name: adv.company_membership.display_name,
          title:         "Salary advance — #{gbp_raw(adv.amount)}",
          badge:         "Advance",
          badge_color:   "bg-blue-50 text-blue-700",
          date:          adv.applied_at,
          path:          admin_salary_advance_path(@current_company.slug, adv)
        }
      end

      pending_savings_plans.each do |plan|
        actions << {
          type:          "savings_plan",
          record:        plan,
          employee_name: plan.company_membership.display_name,
          title:         "Savings plan — #{plan.name}",
          badge:         "Savings",
          badge_color:   "bg-primary-50 text-primary-700",
          date:          plan.created_at,
          approve_path:  approve_form_admin_savings_plan_path(@current_company.slug, plan),
          decline_path:  decline_form_admin_savings_plan_path(@current_company.slug, plan)
        }
      end

      pending_withdrawals.each do |wr|
        actions << {
          type:          "withdrawal",
          record:        wr,
          employee_name: wr.company_membership.display_name,
          title:         "Withdrawal — #{gbp_raw(wr.amount)}",
          badge:         "Withdrawal",
          badge_color:   "bg-orange-50 text-orange-700",
          date:          wr.requested_at,
          approve_path:  approve_form_admin_withdrawal_request_path(@current_company.slug, wr),
          decline_path:  decline_form_admin_withdrawal_request_path(@current_company.slug, wr)
        }
      end

      expiring_invites.each do |m|
        actions << {
          type:          "invite_expiring",
          record:        m,
          employee_name: m.display_name,
          title:         "Invitation expiring soon",
          badge:         "Invite",
          badge_color:   "bg-amber-50 text-amber-700",
          date:          m.invitation_sent_at,
          path:          admin_company_memberships_path(@current_company.slug)
        }
      end

      rtw_expiring.each do |profile|
        actions << {
          type:          "rtw_expiry",
          record:        profile,
          employee_name: profile.company_membership.display_name,
          title:         "Right to work expiring #{profile.right_to_work_expiry&.strftime("%d %b %Y")}",
          badge:         "RTW",
          badge_color:   "bg-red-50 text-red-700",
          date:          profile.right_to_work_expiry&.to_time || Time.current,
          path:          admin_employee_profile_path(@current_company.slug, profile)
        }
      end

      actions.sort_by { |a| a[:date] || Time.current }
    end

    private

    def pending_advances
      SalaryAdvance
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(company_membership: :user)
        .order(applied_at: :asc)
    end

    def pending_savings_plans
      SavingsPlan
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(company_membership: :user)
        .order(created_at: :asc)
    end

    def pending_withdrawals
      WithdrawalRequest
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(company_membership: :user)
        .order(requested_at: :asc)
    end

    def expiring_invites
      @current_company.company_memberships
        .kept
        .pending_invites
        .where("invitation_sent_at < ?", 36.hours.ago)
        .order(invitation_sent_at: :asc)
    end

    def rtw_expiring
      EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .kept
        .where("right_to_work_expiry BETWEEN ? AND ?", Date.current, 60.days.from_now)
        .includes(company_membership: :user)
        .order(:right_to_work_expiry)
    end

    def gbp_raw(amount)
      symbol = @current_company&.currency_symbol.presence || "£"
      ActionController::Base.helpers.number_to_currency(amount || 0, unit: symbol, precision: 2, delimiter: ",")
    end
  end
end
