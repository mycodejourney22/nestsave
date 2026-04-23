class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_company
  skip_before_action :set_current_membership

  def new
    @company = Company.new
    @user    = User.new
  end

  def create
    @company = Company.new(company_params)
    @user    = User.new(user_params)

    ActiveRecord::Base.transaction do
      @user.save!
      @company.save!

      membership = CompanyMembership.create!(
        user:      @user,
        company:   @company,
        role:      :super_admin,
        status:    :active,
        joined_at: Time.current
      )

      HR::CreateEmployeeProfileService.call(
        membership:     membership,
        profile_params: {
          job_title:             "Owner",
          employment_type:       "full_time",
          employment_start_date: Date.current
        },
        initial_salary: nil,
        current_admin:  @user
      )
    end

    # Onboarding email sequence
    OnboardingMailer.employer_welcome(@user).deliver_later
    OnboardingNudgeJob.set(wait: 2.days).perform_later(@user.id)
    OnboardingCheckinJob.set(wait: 5.days).perform_later(@user.id)

    sign_in(@user)
    redirect_to admin_dashboard_path(@company.slug), notice: "Welcome to NestSave, #{@company.name}!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private

  def company_params
    params.require(:company).permit(:name, :slug, :payroll_email, :country, :currency, :currency_symbol, :payroll_day, :timezone)
  end

  def user_params
    params.require(:user).permit(:full_name, :email, :password, :password_confirmation)
  end
end
