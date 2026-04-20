class PagesController < ApplicationController
  layout "landing"

  skip_before_action :authenticate_user!
  skip_before_action :set_current_company
  skip_before_action :set_current_membership

  def home
    if user_signed_in?
      membership = current_user.company_memberships.kept.active.first
      if membership
        slug = membership.company.slug
        redirect_to membership.hr_or_above? ? admin_dashboard_path(slug) : employee_dashboard_path(slug)
      else
        redirect_to new_user_session_path
      end
    end
  end
end
