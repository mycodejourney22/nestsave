class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_current_company, unless: :devise_controller?
  before_action :set_current_membership, unless: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def set_current_company
    @current_company = Company.kept.active.find_by!(slug: params[:company_slug])
  end

  def set_current_membership
    @current_membership = current_user.active_membership_for(@current_company)
    redirect_to root_path, alert: "You are not a member of this company." unless @current_membership
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

  def require_studio_manager!
    unless @current_membership&.studio_manager_or_above?
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

  def after_sign_in_path_for(resource)
    membership = resource.company_memberships.kept.active.first
    return new_user_session_path unless membership

    slug = membership.company.slug
    membership.hr_or_above? ? admin_dashboard_path(slug) : employee_dashboard_path(slug)
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
