module Admin
  class DocumentsController < ApplicationController
    before_action :require_hr!
    before_action :set_profile
    before_action :set_document, only: [:destroy]

    def index
      @documents = @profile.documents.kept.order(created_at: :desc)
    end

    def new
      @document = Document.new
    end

    def create
      @document = @profile.documents.build(document_params)
      @document.uploaded_by = current_user.id

      if @document.save
        redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "documents"),
                    notice: "Document added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @document.soft_delete!
      redirect_to admin_employee_profile_path(@current_company.slug, @profile, tab: "documents"),
                  notice: "Document removed."
    end

    private

    def set_profile
      @profile = EmployeeProfile
        .joins(:company_membership)
        .where(company_memberships: { company_id: @current_company.id })
        .kept
        .find(params[:employee_profile_id])
    end

    def set_document
      @document = @profile.documents.kept.find(params[:id])
    end

    def document_params
      params.require(:document).permit(:title, :category, :notes, :file)
    end
  end
end
