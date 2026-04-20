class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_company
  skip_before_action :set_current_membership

  before_action :set_membership

  EXPIRY_HOURS = 48

  def show
    @existing_user = User.exists?(email: @membership.invited_email)
  end

  def update
    if User.exists?(email: @membership.invited_email)
      handle_existing_user
    else
      handle_new_user
    end
  end

  private

  def set_membership
    membership = CompanyMembership.find_by(invitation_token: params[:token])

    unless membership
      redirect_to new_user_session_path, alert: "Invalid invitation link." and return
    end

    if membership.invitation_accepted_at.present?
      redirect_to new_user_session_path, alert: "This invitation has already been accepted." and return
    end

    if membership.invitation_sent_at < EXPIRY_HOURS.hours.ago
      redirect_to new_user_session_path, alert: "This invitation has expired. Please contact your admin." and return
    end

    @membership = membership
  end

  def handle_existing_user
    @existing_user = true
    user = User.find_by(email: @membership.invited_email)

    unless user.valid_password?(params[:password])
      flash.now[:alert] = "Incorrect password."
      render :show, status: :unprocessable_entity and return
    end

    accept_invitation(@membership, user)
    sign_in(user)
    redirect_to after_accept_path(@membership),
                notice: "Welcome back, #{user.full_name.split.first}! Your account is now active."
  end

  def handle_new_user
    @existing_user = false
    user = User.new(
      full_name:             @membership.invited_name,
      email:                 @membership.invited_email,
      password:              params[:password],
      password_confirmation: params[:password_confirmation]
    )

    unless user.save
      @user_errors = user.errors
      render :show, status: :unprocessable_entity and return
    end

    accept_invitation(@membership, user)
    sign_in(user)
    redirect_to after_accept_path(@membership),
                notice: "Welcome to NestSave, #{user.full_name.split.first}!"
  end

  def accept_invitation(membership, user)
    membership.update!(
      user:                   user,
      status:                 :active,
      joined_at:              Time.current,
      invitation_accepted_at: Time.current
    )
  end

  def after_accept_path(membership)
    slug = membership.company.slug
    membership.hr_or_above? ? admin_dashboard_path(slug) : employee_dashboard_path(slug)
  end
end
