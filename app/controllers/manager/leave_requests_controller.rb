module Manager
  class LeaveRequestsController < ApplicationController
    before_action :require_team_manager!
    before_action :set_request, only: [:approve, :decline]

    def index
      base = LeaveRequest
               .joins(employee_profile: { company_membership: :company })
               .where(company_memberships: { company_id: @current_company.id })
               .where(employee_profiles: { team_id: @current_membership.team_id })
               .includes(:employee_profile, :leave_type)

      @pending_requests = base.pending.order(requested_at: :asc)
      @recent_requests  = base.where(status: %w[manager_approved declined])
                              .order(updated_at: :desc)
                              .limit(50)
    end

    def approve
      result = Leave::ManagerReviewService.call(
        request:  @leave_request,
        reviewer: current_user,
        approved: true,
        note:     params[:note]
      )
      respond result, "approved"
    end

    def decline
      result = Leave::ManagerReviewService.call(
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
                         .where(employee_profiles: { team_id: @current_membership.team_id })
                         .find(params[:id])
    end

    def respond(result, action)
      if result.success?
        redirect_to manager_leave_requests_path(@current_company.slug),
                    notice: "Leave request #{action}."
      else
        redirect_to manager_leave_requests_path(@current_company.slug),
                    alert: result.error
      end
    end
  end
end
