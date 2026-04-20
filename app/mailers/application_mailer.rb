class ApplicationMailer < ActionMailer::Base
  default from: "NestSave <notifications@363photography.org>"
  layout "mailer"

  helper :mailer

  private

  def nestsave_subject(text)
    "[NestSave] #{text}"
  end
end
