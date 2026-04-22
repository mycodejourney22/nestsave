require "csv"

module Admin
  class PayrollRunsController < ApplicationController
    before_action :require_hr!
    before_action :set_run, only: [:show, :destroy, :finalise, :reopen, :send_payslips, :export_csv]

    def index
      @runs = @current_company.payroll_runs
                              .recent
                              .includes(:payroll_entries)
    end

    def new
      @month    = Date.current.month
      @year     = Date.current.year
      @existing = @current_company.payroll_runs.find_by(month: @month, year: @year)
    end

    def create
      result = Payroll::CreateRunService.call(
        company:    @current_company,
        month:      params[:month].to_i,
        year:       params[:year].to_i,
        created_by: current_user
      )
      if result.success?
        redirect_to admin_payroll_run_path(@current_company.slug, result.value),
                    notice: "#{result.value.period_label} payroll created with #{result.value.payroll_entries.count} entries."
      else
        redirect_to admin_payroll_runs_path(@current_company.slug),
                    alert: result.error
      end
    end

    def show
      @entries = @run.payroll_entries
                     .includes(:payroll_items, employee_profile: { company_membership: :user })
                     .order(:created_at)
    end

    def destroy
      unless @run.draft?
        return redirect_to admin_payroll_runs_path(@current_company.slug),
                           alert: "Only draft payroll runs can be deleted."
      end
      @run.destroy!
      redirect_to admin_payroll_runs_path(@current_company.slug),
                  notice: "#{@run.period_label} payroll run deleted."
    end

    def finalise
      result = Payroll::FinaliseRunService.call(run: @run, admin: current_user)
      redirect_with_result(result, "Payroll finalised.", "Could not finalise")
    end

    def reopen
      result = Payroll::ReopenRunService.call(run: @run, admin: current_user)
      redirect_with_result(result, "Payroll reopened for editing.", "Could not reopen")
    end

    def send_payslips
      result = Payroll::SendPayslipsService.call(run: @run, admin: current_user)
      redirect_with_result(result, "Payslips sent to all employees.", "Could not send payslips")
    end

    def export_csv
      entries = @run.payroll_entries
                    .includes(:payroll_items, employee_profile: { company_membership: :user })

      csv_data = CSV.generate(headers: true) do |csv|
        csv << ["Employee", "Team", "Base Salary", "Total Earnings", "Total Deductions", "Net Pay"]
        entries.each do |entry|
          csv << [
            entry.display_name,
            entry.employee_profile.team&.name || "Company-wide",
            entry.base_salary,
            entry.total_earnings,
            entry.total_deductions,
            entry.net_pay
          ]
        end
        csv << [
          "TOTAL", "",
          entries.sum(:base_salary),
          entries.sum(:total_earnings),
          entries.sum(:total_deductions),
          entries.sum(:net_pay)
        ]
      end

      send_data csv_data,
                filename: "payroll_#{@run.period_label.downcase.gsub(" ", "_")}.csv",
                type: "text/csv"
    end

    private

    def set_run
      @run = @current_company.payroll_runs.find(params[:id])
    end

    def redirect_with_result(result, success_msg, error_prefix)
      if result.success?
        redirect_to admin_payroll_run_path(@current_company.slug, @run), notice: success_msg
      else
        redirect_to admin_payroll_run_path(@current_company.slug, @run),
                    alert: "#{error_prefix}: #{result.error}"
      end
    end
  end
end
