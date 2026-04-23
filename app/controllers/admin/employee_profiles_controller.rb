module Admin
  class EmployeeProfilesController < ApplicationController
    before_action :require_hr!
    before_action :set_profile, only: [:show, :edit, :update]

    def index
      @memberships = @current_company.company_memberships
                                     .kept
                                     .includes(:user, :employee_profile)
                                     .order(created_at: :asc)

      @stats = {
        total:       @memberships.count,
        active:      @memberships.select { |m| m.status == "active" }.count,
        departments: @memberships.filter_map { |m| m.employee_profile&.department }.uniq.count
      }
    end

    def show
      @tab              = params[:tab] || "overview"
      @membership       = @profile.company_membership
      @pending_invite   = @membership.pending?
      @display_name     = @membership.display_name
      @display_email    = @membership.display_email
      @display_initials = @membership.display_initials
      @employment_histories = @profile.employment_histories.ordered
      @salary_histories     = @profile.salary_histories.order(effective_date: :desc)
      @documents        = @profile.documents.kept.order(created_at: :desc)
      @bank_detail      = @profile.active_bank_detail
      @emergency_contacts = @profile.emergency_contacts.order(primary: :desc, created_at: :asc)
      @references       = @profile.employee_references.order(created_at: :asc)
      @savings_plans    = @membership.savings_plans.order(created_at: :desc)
      @advances         = @membership.salary_advances.kept.order(applied_at: :desc)
      @leave_types      = @current_company.leave_types.active.order(:name)
      existing_balances = LeaveBalance.for_employee_this_year(@profile).includes(:leave_type)
      @leave_balances   = existing_balances.index_by(&:leave_type_id)
      @leave_requests   = @profile.leave_requests.includes(:leave_type).order(requested_at: :desc)
    end

    def edit
      @teams      = @current_company.teams.active.order(:name)
      @membership = @profile.company_membership
    end

    def update
      @teams      = @current_company.teams.active.order(:name)
      @membership = @profile.company_membership

      ActiveRecord::Base.transaction do
        # Full name lives on User
        if params.dig(:user, :full_name).present?
          @membership.user&.update!(full_name: params[:user][:full_name].strip)
        end

        # Role lives on CompanyMembership
        new_role = params.dig(:company_membership, :role)
        if new_role.present? && CompanyMembership::ROLES.include?(new_role)
          @membership.update!(role: new_role)
        end

        # Salary — only record history if value actually changed
        new_salary_str = params[:new_salary].to_s.gsub(",", "").strip
        if new_salary_str.present? && new_salary_str.to_f > 0
          if new_salary_str.to_f.round(2) != @profile.current_salary.to_f.round(2)
            result = HR::RecordSalaryChangeService.call(
              profile:        @profile,
              new_amount:     new_salary_str,
              reason:         "Updated by HR admin",
              effective_date: Date.today,
              changed_by:     current_user
            )
            raise ActiveRecord::RecordInvalid, result.error unless result.success?
          end
        end

        @profile.update!(profile_params)
      end

      redirect_to admin_employee_profile_path(@current_company.slug, @profile),
                  notice: "Employee updated."
    rescue ActiveRecord::RecordInvalid => e
      @profile.errors.add(:base, e.message) unless @profile.errors.any?
      render :edit, status: :unprocessable_entity
    rescue => e
      flash.now[:alert] = e.message
      render :edit, status: :unprocessable_entity
    end

    private

    def set_profile
      @profile = EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .kept
        .find(params[:id])
    end

    def profile_params
      params.require(:employee_profile).permit(
        :preferred_name, :gender, :date_of_birth, :phone, :personal_email,
        :employment_type, :department_id, :team_id, :job_title,
        :employment_start_date, :employment_end_date,
        :right_to_work_status, :right_to_work_expiry,
        :address_line_1, :address_line_2, :city, :postcode, :country, :nationality
      )
    end
  end
end
