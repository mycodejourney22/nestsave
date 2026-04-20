module Employee
  class WithdrawalRequestsController < ApplicationController
    before_action :require_employee!
    before_action :set_plan

    def new
      @request = WithdrawalRequest.new
    end

    def create
      result = WithdrawalRequests::CreateService.call(
        membership:   @current_membership,
        savings_plan: @plan,
        params:       withdrawal_params
      )

      if result.success?
        redirect_to employee_savings_plan_path(@current_company.slug, @plan),
                    notice: "Withdrawal request submitted. Your payroll manager will review it."
      else
        @request = WithdrawalRequest.new(withdrawal_params)
        @request.errors.add(:base, result.error)
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @plan = @current_membership.savings_plans.kept.find(params[:savings_plan_id])
    end

    def withdrawal_params
      params.require(:withdrawal_request).permit(:amount, :reason)
    end
  end
end
