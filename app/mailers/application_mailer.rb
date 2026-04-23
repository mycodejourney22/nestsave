class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAILER_FROM"]
  layout "mailer"

  helper :mailer

  private

  def nestsave_subject(text)
    "[NestSave] #{text}"
  end
end
