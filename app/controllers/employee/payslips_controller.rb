module Employee
  class PayslipsController < ApplicationController
    before_action :require_employee!

    def index
      @payslips = PayrollEntry
                    .joins(:payroll_run)
                    .where(
                      employee_profile: @current_membership.employee_profile,
                      payroll_runs: {
                        company_id: @current_company.id,
                        status:     "payslips_sent"
                      }
                    )
                    .includes(:payroll_run)
                    .order("payroll_runs.year DESC, payroll_runs.month DESC")
    end

    def show
      @entry = PayrollEntry
                 .joins(:payroll_run)
                 .where(
                   id:               params[:id],
                   employee_profile: @current_membership.employee_profile,
                   payroll_runs: {
                     company_id: @current_company.id,
                     status:     "payslips_sent"
                   }
                 )
                 .includes(:payroll_run, :payroll_items)
                 .first!
      @run        = @entry.payroll_run
      @profile    = @entry.employee_profile
      @earnings   = @entry.earnings_items
      @deductions = @entry.deductions_items
    end
  end
end
