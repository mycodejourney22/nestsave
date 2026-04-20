module Admin
  class SalaryHistoriesController < ApplicationController
    before_action :require_hr!
    before_action :set_profile

    def index
      @salary_histories = @profile.salary_histories.order(effective_date: :desc)
    end

    def new
      @salary_history = SalaryHistory.new(effective_date: Date.current)
    end

    def create
      result = HR::RecordSalaryChangeService.call(
        profile:        @profile,
        new_amount:     params[:salary_history][:amount],
        reason:         params[:salary_history][:reason],
        effective_date: params[:salary_history][:effective_date],
        changed_by:     current_user
      )

      if result.success?
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "salary_history"),
                    notice: "Salary change recorded."
      else
        @salary_history = SalaryHistory.new(salary_history_params)
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_profile
      @profile = EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .kept
        .find(params[:employee_profile_id])
    end

    def salary_history_params
      params.require(:salary_history).permit(:amount, :reason, :effective_date, :notes)
    end
  end
end
