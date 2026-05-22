module Admin
  class SalaryAdvancesController < ApplicationController
    include Admin::PendingActionsConcern

    before_action :require_hr!
    before_action :set_advance, except: [:index]
    layout false, only: [:approve_form, :decline_form, :disburse_form]

    def index
      membership_ids = @current_company.company_memberships.active.pluck(:id)
      @advances = SalaryAdvance
        .where(company_membership_id: membership_ids)
        .where(status: params[:status].presence || "pending")
        .includes(company_membership: [:employee_profile, :user])
        .order(created_at: :desc)
    end

    def show; end
    def approve_form; end
    def decline_form; end
    def disburse_form; end

    def edit
      unless @advance.pending? || @advance.approved?
        redirect_to admin_salary_advance_path(@current_company.slug, @advance),
                    alert: "Only pending or approved advances can be amended."
      end
    end

    def update
      result = SalaryAdvances::AmendService.call(
        advance:          @advance,
        admin:            current_user,
        amount:           advance_params[:amount],
        repayment_months: advance_params[:repayment_months],
        note:             advance_params[:note]
      )

      if result.success?
        redirect_to admin_salary_advance_path(@current_company.slug, @advance),
                    notice: "Advance updated successfully."
      else
        flash.now[:alert] = result.error
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      result = SalaryAdvances::ReviewService.call(
        advance:  @advance,
        admin:    current_user,
        approved: true,
        note:     params[:note]
      )
      respond_with_result(result, "Advance approved. Repayment schedule generated.", "Could not approve")
    end

    def decline
      result = SalaryAdvances::ReviewService.call(
        advance:  @advance,
        admin:    current_user,
        approved: false,
        note:     params[:note]
      )
      respond_with_result(result, "Advance declined.", "Could not decline")
    end

    def disburse
      result = SalaryAdvances::DisburseService.call(advance: @advance, admin: current_user)
      respond_with_result(result, "Advance marked as disbursed.", "Could not mark as disbursed")
    end

    private

    def advance_params
      params.require(:salary_advance).permit(:amount, :repayment_months, :note)
    end

    def set_advance
      @advance = SalaryAdvance
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .find(params[:id])
    end

    def respond_with_result(result, success_msg, error_msg)
      if result.success?
        flash.now[:notice] = success_msg
      else
        flash.now[:alert] = "#{error_msg}: #{result.error}"
      end

      respond_to do |format|
        format.turbo_stream do
          @pending_actions = build_pending_actions
          render turbo_stream: [
            turbo_stream.remove("modal"),
            turbo_stream.replace("flash_messages") { render_to_string(partial: "shared/flash_stream") },
            turbo_stream.replace("pending_actions") {
              render_to_string(partial: "admin/dashboard/pending_actions",
                               locals:  { pending_actions: @pending_actions })
            }
          ]
        end
        format.html do
          if result.success?
            redirect_to admin_dashboard_path(@current_company.slug), notice: success_msg
          else
            redirect_to admin_dashboard_path(@current_company.slug), alert: "#{error_msg}: #{result.error}"
          end
        end
      end
    end
  end
end
