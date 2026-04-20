module Admin
  class EmploymentHistoriesController < ApplicationController
    before_action :require_hr!
    before_action :set_profile
    before_action :set_history, only: [:edit, :update, :destroy]

    def new
      @history = @profile.employment_histories.build
    end

    def create
      @history = @profile.employment_histories.build(history_params)
      if @history.save
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "work_history"),
                    notice: "Employment history added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @history.update(history_params)
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "work_history"),
                    notice: "Employment history updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @history.destroy
      redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "work_history"),
                  notice: "Employment history removed."
    end

    private

    def set_profile
      @profile = EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .kept
        .find(params[:employee_profile_id])
    end

    def set_history
      @history = @profile.employment_histories.find(params[:id])
    end

    def history_params
      params.require(:employment_history).permit(
        :company_name, :job_title, :start_date,
        :end_date, :location, :reason_for_leaving, :notes
      )
    end
  end
end
