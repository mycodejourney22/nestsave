module WithdrawalRequests
  class CreateService
    def self.call(membership:, savings_plan:, params:)
      new(membership, savings_plan, params).call
    end

    def initialize(membership, savings_plan, params)
      @membership   = membership
      @savings_plan = savings_plan
      @params       = params
    end

    def call
      request = @savings_plan.withdrawal_requests.build(
        company_membership: @membership,
        amount:             @params[:amount],
        reason:             @params[:reason],
        requested_at:       Time.current,
        status:             :pending
      )

      return Result.failure(request.errors.full_messages.join(", ")) unless request.save

      notify_admins(request)
      Result.success(request)
    rescue => e
      Result.failure(e.message)
    end

    private

    def notify_admins(request)
      @membership.company.hr_admins.each do |admin|
        PayrollAdminMailer.withdrawal_requested(admin, request).deliver_later

        Notification.create!(
          user:       admin,
          notifiable: request,
          channel:    :email,
          event:      :withdrawal_requested,
          sent:       true,
          sent_at:    Time.current
        )
      end
    end
  end
end
