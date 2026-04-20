class PayrollAdminMailer < ApplicationMailer
  # Confirmation sent to the admin after they send an invitation
  def invite_employee(membership)
    @membership      = membership
    @company         = membership.company
    @invited_name    = membership.invited_name
    @invited_email   = membership.invited_email
    @profile         = membership.employee_profile
    @team_url        = admin_company_memberships_url(company_slug: @company.slug)

    mail to:      membership.inviter&.email || @company.payroll_email,
         subject: "[NestSave] #{@invited_name} has been invited to NestSave — #{@company.name}"
  end

  # Invitation email sent to the employee with the accept link
  def invite_employee_to_platform(membership)
    @membership   = membership
    @company      = membership.company
    @invited_name = membership.invited_name
    @profile      = membership.employee_profile
    @accept_url   = accept_invitation_url(token: membership.invitation_token)

    mail to:      membership.invited_email,
         subject: "[NestSave] #{membership.inviter&.full_name || @company.name} invited you to NestSave at #{@company.name}"
  end

  def savings_plan_submitted(admin, plan)
    @admin          = admin
    @plan           = plan
    @employee       = plan.company_membership.user
    @company        = plan.company_membership.company
    @dashboard_url  = admin_dashboard_url(company_slug: @company.slug)

    mail to:      admin.email,
         subject: "[NestSave] Action required — New savings plan from #{@employee.full_name}"
  end

  def withdrawal_requested(admin, request)
    @admin         = admin
    @request       = request
    @employee      = request.company_membership.user
    @company       = request.company_membership.company
    @dashboard_url = admin_dashboard_url(company_slug: @company.slug)

    mail to:      admin.email,
         subject: "[NestSave] Action required — Withdrawal request from #{@employee.full_name}"
  end

  def advance_submitted(admin, advance)
    @admin         = admin
    @advance       = advance
    @employee      = advance.company_membership.user
    @company       = advance.company_membership.company
    @review_url    = admin_salary_advance_url(company_slug: @company.slug, id: advance.id)
    @dashboard_url = admin_dashboard_url(company_slug: @company.slug)

    mail to:      admin.email,
         subject: "[NestSave] Action required — Salary advance request from #{@employee.full_name}"
  end

  def monthly_deductions_summary(admin, company, summary)
    @admin         = admin
    @company       = company
    @summary       = summary
    @dashboard_url = admin_dashboard_url(company_slug: company.slug)
    @period        = Date.current.strftime("%B %Y")

    mail to:      admin.email,
         subject: "[NestSave] #{company.name} — Payroll deductions for #{@period}"
  end
end
