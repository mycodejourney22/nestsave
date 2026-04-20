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
      @leave_balances   = LeaveBalance.for_employee_this_year(@profile).includes(:leave_type)
      @leave_requests   = @profile.leave_requests.includes(:leave_type).order(requested_at: :desc)
    end

    def edit
      @teams = @current_company.teams.active.order(:name)
    end

    def update
      @teams = @current_company.teams.active.order(:name)
      if @profile.update(profile_params)
        redirect_to admin_employee_profile_path(@current_company.slug, @profile),
                    notice: "Profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
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
