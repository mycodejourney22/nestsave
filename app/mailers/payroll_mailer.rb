class PayrollMailer < ApplicationMailer
  def leave_requested(admin, request)
    @admin   = admin
    @request = request
    @company = request.employee_profile.company_membership.company
    @url     = admin_leave_requests_url(company_slug: @company.slug)

    mail to:      admin.email,
         subject: "[NestSave] New leave request from #{request.employee_profile.full_name}"
  end
end
