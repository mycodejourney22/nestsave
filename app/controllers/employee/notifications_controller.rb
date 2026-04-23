module Employee
  class NotificationsController < ApplicationController
    before_action :require_employee!

    def index
      @notifications = current_user.notifications
                                   .where(company: @current_company)
                                   .for_bell
                                   .limit(50)
      # Mark all as read on visit
      current_user.notifications
                  .where(company: @current_company)
                  .unread
                  .where.not(title: nil)
                  .update_all(read: true, read_at: Time.current)
    end

    def mark_read
      notification = current_user.notifications
                                 .where(company: @current_company)
                                 .find(params[:id])
      notification.mark_read!
      head :ok
    end
  end
end
