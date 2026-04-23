class OnboardingCheckinJob < ApplicationJob
  queue_as :onboarding

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    OnboardingMailer.employer_checkin(user).deliver_later
  end
end
