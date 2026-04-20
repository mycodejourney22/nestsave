module Admin
  class CompanyMembershipsController < ApplicationController
    before_action :require_hr!
    before_action :set_membership, only: [:edit, :update, :destroy]

    def index
      @memberships = @current_company.company_memberships
                                     .kept
                                     .includes(:user, employee_profile: :team)
                                     .order(created_at: :asc)
      @teams = @current_company.teams.active.order(:name)
    end

    def new
      @membership = CompanyMembership.new
      @teams = @current_company.teams.active.order(:name)
    end

    def create
      full_name = membership_params[:full_name].to_s.strip
      email     = membership_params[:email].to_s.strip.downcase
      token     = SecureRandom.urlsafe_base64(32)

      ActiveRecord::Base.transaction do
        @membership = CompanyMembership.create!(
          company:           @current_company,
          role:              :employee,
          status:            :pending,
          inviter:           current_user,
          invited_name:      full_name,
          invited_email:     email,
          invitation_token:  token,
          invitation_sent_at: Time.current
        )

        result = HR::CreateEmployeeProfileService.call(
          membership:     @membership,
          profile_params: {
            job_title:             membership_params[:job_title],
            department_id:         membership_params[:department_id],
            employment_type:       membership_params[:employment_type],
            employment_start_date: membership_params[:employment_start_date]
          },
          initial_salary: membership_params[:initial_salary],
          current_admin:  current_user
        )

        raise ActiveRecord::Rollback, result.error unless result.success?

        if membership_params[:team_id].present?
          result.value.update!(team_id: membership_params[:team_id])
        end
      end

      if @membership.persisted? && @membership.employee_profile.present?
        PayrollAdminMailer.invite_employee_to_platform(@membership).deliver_later
        PayrollAdminMailer.invite_employee(@membership).deliver_later
        redirect_to admin_company_memberships_path(@current_company.slug),
                    notice: "Invitation sent to #{email}."
      else
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid => e
      @membership ||= CompanyMembership.new
      @membership.errors.add(:base, e.message)
      @teams = @current_company.teams.active.order(:name)
      render :new, status: :unprocessable_entity
    end

    def edit; end

    def destroy
      unless @membership.cancellable?
        return respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("flash_messages") { render_to_string(partial: "shared/flash_stream", locals: {}) } }
          format.html { redirect_to admin_company_memberships_path(@current_company.slug), alert: "Only pending invitations can be cancelled." }
        end
      end

      @membership.soft_delete!

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Invitation to #{@membership.display_email} cancelled."
          render turbo_stream: [
            turbo_stream.remove("membership_#{@membership.id}"),
            turbo_stream.replace("flash_messages") { render_to_string(partial: "shared/flash_stream") }
          ]
        end
        format.html do
          redirect_to admin_company_memberships_path(@current_company.slug),
                      notice: "Invitation to #{@membership.display_email} cancelled."
        end
      end
    end

    def update
      if @membership.update(edit_membership_params)
        redirect_to admin_company_memberships_path(@current_company.slug),
                    notice: "Member updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_membership
      @membership = @current_company.company_memberships.kept.find(params[:id])
    end

    def membership_params
      params.require(:company_membership).permit(
        :full_name, :email, :job_title, :department_id, :team_id,
        :employment_type, :employment_start_date, :initial_salary
      )
    end

    def edit_membership_params
      params.require(:company_membership).permit(:role, :status)
    end
  end
end
