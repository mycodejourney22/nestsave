module Admin
  class LeaveRequestsController < ApplicationController
    before_action :require_hr!
    before_action :set_request, only: [:approve, :decline]

    def index
      base = LeaveRequest
               .joins(employee_profile: { company_membership: :company })
               .where(company_memberships: { company_id: @current_company.id })
               .includes(:employee_profile, :leave_type)

      @pending_requests = base.pending.order(requested_at: :asc)
      @recent_requests  = base.where.not(status: "pending")
                              .order(updated_at: :desc)
                              .limit(50)
    end

    def approve
      result = Leave::ReviewService.call(
        request:  @leave_request,
        reviewer: current_user,
        approved: true,
        note:     params[:note]
      )
      respond result, "approved"
    end

    def decline
      result = Leave::ReviewService.call(
        request:  @leave_request,
        reviewer: current_user,
        approved: false,
        note:     params[:note]
      )
      respond result, "declined"
    end

    private

    def set_request
      @leave_request = LeaveRequest
                         .joins(employee_profile: { company_membership: :company })
                         .where(company_memberships: { company_id: @current_company.id })
                         .find(params[:id])
    end

    def respond(result, action)
      if result.success?
        redirect_to admin_leave_requests_path(@current_company.slug),
                    notice: "Leave request #{action}."
      else
        redirect_to admin_leave_requests_path(@current_company.slug),
                    alert: result.error
      end
    end
  end
end
