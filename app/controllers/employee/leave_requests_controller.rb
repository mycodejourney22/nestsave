module Employee
  class LeaveRequestsController < ApplicationController
    before_action :require_employee!
    before_action :set_profile
    before_action :set_request, only: [:destroy]

    def index
      leave_types  = @current_company.leave_types.active.order(:name)
      existing     = LeaveBalance.for_employee_this_year(@profile)
                                 .includes(:leave_type)
                                 .index_by(&:leave_type_id)

      @balances = leave_types.map do |lt|
        existing[lt.id] || LeaveBalance.new(
          employee_profile: @profile,
          leave_type:       lt,
          year:             Date.current.year,
          total_days:       lt.default_days,
          accrued_days:     lt.requires_balance? ? accrued_days_for(lt) : 0,
          used_days:        0,
          override_days:    0
        )
      end

      @requests = @profile.leave_requests
                          .includes(:leave_type)
                          .order(requested_at: :desc)
    end

    def new
      @leave_types = @current_company.leave_types.active
      @request     = LeaveRequest.new
    end

    def create
      leave_type = @current_company.leave_types.active.find(params.dig(:leave_request, :leave_type_id))
      result = Leave::RequestService.call(
        profile:    @profile,
        leave_type: leave_type,
        params:     leave_request_params
      )
      if result.success?
        redirect_to employee_leave_requests_path(@current_company.slug),
                    notice: "Leave request submitted."
      else
        @leave_types = @current_company.leave_types.active
        @request     = LeaveRequest.new(leave_request_params)
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      if @leave_request.pending?
        @leave_request.update!(status: :cancelled)
        if @leave_request.leave_balance
          @leave_request.leave_balance.decrement!(:used_days, 0)
        end
        redirect_to employee_leave_requests_path(@current_company.slug),
                    notice: "Leave request cancelled."
      else
        redirect_to employee_leave_requests_path(@current_company.slug),
                    alert: "Only pending requests can be cancelled."
      end
    end

    private

    def set_profile
      @profile = @current_membership.employee_profile
    end

    def set_request
      @leave_request = @profile.leave_requests.find(params[:id])
    end

    def accrued_days_for(leave_type)
      return leave_type.default_days unless leave_type.accrues_monthly?
      months = [
        (Date.current.year * 12 + Date.current.month) -
        (@profile.employment_start_date.year * 12 + @profile.employment_start_date.month),
        Date.current.month
      ].min
      (months * leave_type.default_days / 12.0).round(1)
    end

    def leave_request_params
      params.require(:leave_request).permit(:leave_type_id, :start_date, :end_date, :reason)
    end
  end
end
