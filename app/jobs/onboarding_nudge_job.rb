class OnboardingNudgeJob < ApplicationJob
  queue_as :onboarding

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    company = user.companies.first
    return unless company

    # Count active employees other than the admin themselves
    employee_count = company.company_memberships
                            .active
                            .where.not(user_id: user.id)
                            .count

    return if employee_count > 0

    OnboardingMailer.employer_nudge(user).deliver_later
  end
end
