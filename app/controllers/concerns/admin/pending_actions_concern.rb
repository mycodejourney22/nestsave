module Admin
  module PendingActionsConcern
    extend ActiveSupport::Concern

    def build_pending_actions
      actions = []

      # Leave requests — high priority
      LeaveRequest
        .joins(employee_profile: :company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(:leave_type, employee_profile: { company_membership: :user })
        .order(created_at: :asc)
        .each do |r|
          actions << {
            type:         :leave,
            priority:     :high,
            record:       r,
            name:         r.employee_profile.company_membership.display_name,
            description:  "#{r.leave_type.name} · #{r.total_days} #{"day".pluralize(r.total_days)}",
            sub:          "#{r.start_date.strftime("%-d %b")} – #{r.end_date.strftime("%-d %b %Y")}",
            time:         r.created_at,
            approvable:   true,
            approve_path: approve_admin_leave_request_path(@current_company.slug, r),
            decline_path: decline_admin_leave_request_path(@current_company.slug, r)
          }
        end

      # Salary advance requests — high priority
      SalaryAdvance
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(company_membership: :user)
        .order(applied_at: :asc)
        .each do |a|
          actions << {
            type:         :advance,
            priority:     :high,
            record:       a,
            name:         a.company_membership.display_name,
            description:  "Salary advance · #{gbp_raw(a.amount)}",
            sub:          "#{a.repayment_months} month repayment",
            time:         a.applied_at,
            approvable:   true,
            approve_path: approve_form_admin_salary_advance_path(@current_company.slug, a),
            decline_path: decline_form_admin_salary_advance_path(@current_company.slug, a)
          }
        end

      # Savings plan approvals — high priority
      SavingsPlan
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(company_membership: :user)
        .order(created_at: :asc)
        .each do |p|
          actions << {
            type:         :savings,
            priority:     :high,
            record:       p,
            name:         p.company_membership.display_name,
            description:  "Savings plan · #{gbp_raw(p.monthly_amount)}/mo",
            sub:          p.name,
            time:         p.created_at,
            approvable:   true,
            approve_path: approve_form_admin_savings_plan_path(@current_company.slug, p),
            decline_path: decline_form_admin_savings_plan_path(@current_company.slug, p)
          }
        end

      # Withdrawal requests — medium priority
      WithdrawalRequest
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .pending
        .includes(company_membership: :user, savings_plan: [])
        .order(requested_at: :asc)
        .each do |w|
          actions << {
            type:         :savings,
            priority:     :medium,
            record:       w,
            name:         w.company_membership.display_name,
            description:  "Savings withdrawal · #{gbp_raw(w.amount)}",
            sub:          "From #{w.savings_plan.name}",
            time:         w.requested_at,
            approvable:   true,
            approve_path: approve_form_admin_withdrawal_request_path(@current_company.slug, w),
            decline_path: decline_form_admin_withdrawal_request_path(@current_company.slug, w)
          }
        end

      # Expiring invites — medium priority
      @current_company.company_memberships
        .kept
        .pending_invites
        .where("invitation_sent_at < ?", 36.hours.ago)
        .order(invitation_sent_at: :asc)
        .each do |m|
          actions << {
            type:         :hr,
            priority:     :medium,
            record:       m,
            name:         m.display_name,
            description:  "Invite pending · No account created yet",
            sub:          "Invited #{(((Time.current - m.invitation_sent_at) / 3600).round)} hours ago",
            time:         m.invitation_sent_at,
            approvable:   false,
            action_label: "Resend",
            action_path:  admin_company_memberships_path(@current_company.slug)
          }
        end

      # Expiring right to work — low priority
      EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id, status: "active" })
        .where("right_to_work_expiry BETWEEN ? AND ?", Date.current, 60.days.from_now)
        .includes(company_membership: :user)
        .order(:right_to_work_expiry)
        .each do |p|
          days_left = (p.right_to_work_expiry - Date.current).to_i
          actions << {
            type:         :hr,
            priority:     :low,
            record:       p,
            name:         p.company_membership.display_name,
            description:  "Right to work expires in #{days_left} #{"day".pluralize(days_left)}",
            sub:          "#{p.right_to_work_status} · Expires #{p.right_to_work_expiry.strftime("%-d %b %Y")}",
            time:         p.right_to_work_expiry.to_time,
            approvable:   false,
            action_label: "View profile",
            action_path:  admin_employee_profile_path(@current_company.slug, p)
          }
        end

      actions.sort_by { |a| [priority_order(a[:priority]), a[:time]] }
    end

    private

    def priority_order(p)
      { high: 0, medium: 1, low: 2 }[p] || 3
    end

    def gbp_raw(amount)
      symbol = @current_company&.currency_symbol.presence || "£"
      ActionController::Base.helpers.number_to_currency(amount || 0, unit: symbol, precision: 2, delimiter: ",")
    end
  end
end
