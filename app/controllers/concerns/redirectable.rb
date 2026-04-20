module Redirectable
  def after_sign_in_path_for(resource)
    membership = resource.company_memberships.kept.active.first
    return root_path unless membership

    company_slug = membership.company.slug

    if membership.hr_or_above?
      admin_dashboard_path(company_slug)
    else
      employee_dashboard_path(company_slug)
    end
  end
end
