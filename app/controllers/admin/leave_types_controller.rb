module Admin
  class LeaveTypesController < ApplicationController
    before_action :require_hr!
    before_action :set_leave_type, only: [:edit, :update]

    def index
      @leave_types = @current_company.leave_types.order(:name)
    end

    def new
      @leave_type = LeaveType.new
    end

    def create
      @leave_type = @current_company.leave_types.build(leave_type_params)
      if @leave_type.save
        redirect_to admin_leave_types_path(@current_company.slug), notice: "Leave type created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @leave_type.update(leave_type_params)
        redirect_to admin_leave_types_path(@current_company.slug), notice: "Leave type updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_leave_type
      @leave_type = @current_company.leave_types.find(params[:id])
    end

    def leave_type_params
      params.require(:leave_type).permit(
        :name, :category, :default_days,
        :requires_balance, :accrues_monthly, :active
      )
    end
  end
end
