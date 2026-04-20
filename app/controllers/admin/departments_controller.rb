module Admin
  class DepartmentsController < ApplicationController
    before_action :require_hr!
    before_action :set_department, only: [:edit, :update, :destroy]

    def index
      @departments = @current_company.departments.active.order(:name)
    end

    def new
      @department = @current_company.departments.new
    end

    def create
      @department = @current_company.departments.new(department_params)
      if @department.save
        redirect_to admin_departments_path(@current_company.slug), notice: "Department created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @department.update(department_params)
        redirect_to admin_departments_path(@current_company.slug), notice: "Department updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @department.soft_delete!
      redirect_to admin_departments_path(@current_company.slug), notice: "Department removed."
    end

    private

    def set_department
      @department = @current_company.departments.kept.find(params[:id])
    end

    def department_params
      params.require(:department).permit(:name, :color)
    end
  end
end
