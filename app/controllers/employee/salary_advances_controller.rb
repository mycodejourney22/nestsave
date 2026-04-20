module Employee
  class SalaryAdvancesController < ApplicationController
    before_action :require_employee!
    before_action :set_advance, only: [:show]

    def index
      @advances = @current_membership.salary_advances.kept.order(applied_at: :desc)
    end

    def show
      @schedule = @advance.advance_repayment_schedules.order(:instalment_number)
    end

    def new
      @advance = SalaryAdvance.new
    end

    def create
      result = SalaryAdvances::ApplyService.call(
        membership: @current_membership,
        params:     advance_params
      )

      if result.success?
        redirect_to employee_salary_advance_path(@current_company.slug, result.value),
                    notice: "Salary advance application submitted."
      else
        @advance = SalaryAdvance.new(advance_params)
        @advance.errors.add(:base, result.error)
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_advance
      @advance = @current_membership.salary_advances.kept.find(params[:id])
    end

    def advance_params
      params.require(:salary_advance).permit(:amount, :reason, :repayment_months)
    end
  end
end
