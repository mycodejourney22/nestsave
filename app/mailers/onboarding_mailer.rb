class OnboardingMailer < ApplicationMailer
  def employer_welcome(user)
    @user    = user
    @company = user.companies.first
    @first_name = user.full_name.split.first
    @dashboard_url = admin_dashboard_url(@company.slug)
    mail(
      to:      user.email,
      subject: "Welcome to NestSave — let's get your team set up"
    )
  end

  def employer_nudge(user)
    @user    = user
    @company = user.companies.first
    @first_name = user.full_name.split.first
    @invite_url = new_admin_company_membership_url(@company.slug)
    mail(
      to:      user.email,
      subject: "Have you invited your first employee yet?"
    )
  end

  def employer_checkin(user)
    @user    = user
    @company = user.companies.first
    @first_name = user.full_name.split.first
    @dashboard_url = admin_dashboard_url(@company.slug)
    mail(
      to:      user.email,
      subject: "How's NestSave working for you?"
    )
  end
end
