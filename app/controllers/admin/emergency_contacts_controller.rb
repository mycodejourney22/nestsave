module Admin
  class EmergencyContactsController < ApplicationController
    before_action :require_hr!
    before_action :set_profile
    before_action :set_contact, only: [:edit, :update, :destroy]

    def index
      @contacts = @profile.emergency_contacts.order(primary: :desc, created_at: :asc)
    end

    def new
      @contact = EmergencyContact.new
    end

    def create
      @contact = @profile.emergency_contacts.build(contact_params)

      if @contact.save
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "overview"),
                    notice: "Emergency contact added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @contact.update(contact_params)
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "overview"),
                    notice: "Emergency contact updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @contact.destroy
      redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "overview"),
                  notice: "Emergency contact removed."
    end

    private

    def set_profile
      @profile = EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .kept
        .find(params[:employee_profile_id])
    end

    def set_contact
      @contact = @profile.emergency_contacts.find(params[:id])
    end

    def contact_params
      params.require(:emergency_contact).permit(:full_name, :relationship, :phone, :email, :primary)
    end
  end
end
