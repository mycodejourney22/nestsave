module Admin
  class LeaveBalancesController < ApplicationController
    before_action :require_hr!

    def index
      @profile  = @current_company.company_memberships
                    .kept
                    .joins(:employee_profile)
                    .find { |m| m.employee_profile.id == params[:employee_profile_id] }
                    &.employee_profile ||
                  EmployeeProfile.joins(:company_membership)
                    .where(company_memberships: { company_id: @current_company.id })
                    .find(params[:employee_profile_id])
      @balances = @profile.leave_balances
                    .includes(:leave_type)
                    .where(year: Date.current.year)
                    .order(:created_at)
    end

    def create
      leave_type = @current_company.leave_types.active.find(params[:leave_type_id])
      profile    = EmployeeProfile
                     .joins(:company_membership)
                     .where(company_memberships: { company_id: @current_company.id })
                     .find(params[:employee_profile_id])

      balance = profile.leave_balances.find_or_initialize_by(
        leave_type: leave_type,
        year:       Date.current.year
      )
      if balance.new_record?
        balance.total_days    = leave_type.default_days
        balance.accrued_days  = leave_type.default_days
        balance.used_days     = 0
        balance.override_days = 0
        balance.save!
      end

      result = Leave::OverrideBalanceService.call(
        balance:       balance,
        new_remaining: params[:remaining_days].to_f,
        admin:         current_user,
        reason:        params[:reason]
      )
      if result.success?
        redirect_to admin_employee_profile_path(@current_company.slug, profile, tab: "leave"),
                    notice: "Leave balance initialised."
      else
        redirect_to admin_employee_profile_path(@current_company.slug, profile, tab: "leave"),
                    alert: result.error
      end
    end

    def override
      @balance = LeaveBalance
                   .joins(:employee_profile)
                   .joins("JOIN company_memberships ON company_memberships.id = employee_profiles.company_membership_id")
                   .where(company_memberships: { company_id: @current_company.id })
                   .find(params[:id])
      result = Leave::OverrideBalanceService.call(
        balance:       @balance,
        new_remaining: params[:remaining_days].to_f,
        admin:         current_user,
        reason:        params[:reason]
      )
      if result.success?
        redirect_to admin_employee_profile_path(@current_company.slug, @balance.employee_profile, tab: "leave"),
                    notice: "Leave balance updated."
      else
        redirect_back fallback_location: admin_employee_profiles_path(@current_company.slug),
                      alert: result.error
      end
    end
  end
end
