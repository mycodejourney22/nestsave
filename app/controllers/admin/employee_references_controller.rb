module Admin
  class EmployeeReferencesController < ApplicationController
    before_action :require_hr!
    before_action :set_profile
    before_action :set_reference, only: [:edit, :update]

    def index
      @references = @profile.employee_references.order(created_at: :asc)
    end

    def new
      @reference = EmployeeReference.new
    end

    def create
      @reference = @profile.employee_references.build(reference_params)

      if @reference.save
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "references"),
                    notice: "Reference added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @reference.update(reference_params)
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "references"),
                    notice: "Reference updated."
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
        .find(params[:employee_profile_id])
    end

    def set_reference
      @reference = @profile.employee_references.find(params[:id])
    end

    def reference_params
      params.require(:employee_reference).permit(
        :referee_name, :organisation, :relationship, :email, :phone,
        :status, :requested_on, :received_on, :notes
      )
    end
  end
end
