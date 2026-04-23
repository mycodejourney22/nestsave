class NotificationService
  def self.create(user:, company:, title:, category:, body: nil, link: nil, event: nil)
    return unless user && company

    Notification.create!(
      user:     user,
      company:  company,
      title:    title,
      body:     body,
      link:     link,
      category: category,
      event:    event,
      channel:  :in_app,
      sent:     true,
      sent_at:  Time.current
    )
  rescue => e
    Rails.logger.error("NotificationService.create failed: #{e.message}")
    nil
  end
end
