class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include Redirectable

  before_action :authenticate_user!
  before_action :set_current_company,    unless: :devise_controller?
  before_action :set_current_membership, unless: :devise_controller?
  before_action :load_bell_data,         unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def set_current_company
    @current_company = Company.kept.active.find_by!(slug: params[:company_slug])
  end

  def set_current_membership
    @current_membership = current_user.active_membership_for(@current_company)
    unless @current_membership
      suspended = current_user.company_memberships.kept
                               .find_by(company: @current_company, status: "suspended")
      if suspended
        redirect_to root_path,
          alert: "Your account has been deactivated. Please contact your HR team."
      else
        redirect_to root_path, alert: "You are not a member of this company."
      end
    end
  end

  def require_employee!
    unless @current_membership.present?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_hr!
    unless @current_membership&.hr_or_above?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_team_manager!
    unless @current_membership&.team_manager_or_above?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_super_admin!
    unless @current_membership&.super_admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def user_not_authorized
    redirect_to root_path, alert: "You are not authorised to perform this action."
  end

  def not_found
    redirect_to root_path, alert: "Record not found."
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  def load_bell_data
    return unless @current_company && user_signed_in?
    @unread_count = current_user.notifications
                                .where(company: @current_company)
                                .where.not(title: nil)
                                .unread
                                .count
    @recent_notifications = current_user.notifications
                                        .where(company: @current_company)
                                        .for_bell
                                        .limit(10)
  end
end
