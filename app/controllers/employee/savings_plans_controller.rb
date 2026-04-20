module Employee
  class SavingsPlansController < ApplicationController
    before_action :require_employee!
    before_action :set_plan, only: [:show]

    def index
      @plans = @current_membership.savings_plans.kept.order(created_at: :desc)
    end

    def show; end

    def new
      @plan = SavingsPlan.new
    end

    def create
      result = SavingsPlans::CreateService.call(
        membership: @current_membership,
        params:     savings_plan_params
      )

      if result.success?
        redirect_to employee_savings_plan_path(@current_company.slug, result.value),
                    notice: "Savings plan submitted. Your payroll manager will review it shortly."
      else
        @plan = SavingsPlan.new(savings_plan_params)
        @plan.errors.add(:base, result.error)
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @plan = @current_membership.savings_plans.kept.find(params[:id])
    end

    def savings_plan_params
      params.require(:savings_plan).permit(:name, :monthly_amount, :duration_months, :start_date)
    end
  end
end
