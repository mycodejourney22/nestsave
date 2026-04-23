module SalaryAdvances
  class ApplyService
    def self.call(membership:, params:)
      new(membership, params).call
    end

    def initialize(membership, params)
      @membership = membership
      @params     = params
    end

    def call
      advance = @membership.salary_advances.build(
        amount:           @params[:amount],
        reason:           @params[:reason],
        repayment_months: @params[:repayment_months],
        applied_at:       Time.current,
        status:           :pending
      )

      return Result.failure(advance.errors.full_messages.join(", ")) unless advance.save

      notify_admins(advance)

      NotificationService.create(
        user:     @membership.user,
        company:  @membership.company,
        title:    "Advance request submitted",
        body:     "Your request for #{@membership.company.currency_symbol}#{'%.2f' % advance.amount.to_f} is under review",
        link:     "/#{@membership.company.slug}/employee/salary_advances/#{advance.id}",
        category: "advance",
        event:    "advance_submitted"
      )

      Result.success(advance)
    rescue => e
      Result.failure(e.message)
    end

    private

    def notify_admins(advance)
      @membership.company.hr_admins.each do |admin|
        PayrollAdminMailer.advance_submitted(admin, advance).deliver_later

        Notification.create!(
          user:       admin,
          notifiable: advance,
          channel:    :email,
          event:      :advance_submitted,
          sent:       true,
          sent_at:    Time.current
        )
      end
    end
  end
end
