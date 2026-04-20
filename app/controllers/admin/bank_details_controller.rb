module Admin
  class BankDetailsController < ApplicationController
    before_action :require_hr!
    before_action :set_profile

    def show
      @bank_detail = @profile.active_bank_detail
    end

    def new
      @bank_detail = BankDetail.new
    end

    def create
      @bank_detail = @profile.bank_details.build(bank_detail_params)
      @bank_detail.recorded_by = current_user.id

      if @bank_detail.save
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "bank_details"),
                    notice: "Bank details updated. Previous details deactivated."
      else
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

    def bank_detail_params
      params.require(:bank_detail).permit(:bank_name, :account_name, :account_number, :sort_code)
    end
  end
end
