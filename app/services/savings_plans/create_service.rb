module SavingsPlans
  class CreateService
    def self.call(membership:, params:)
      new(membership, params).call
    end

    def initialize(membership, params)
      @membership = membership
      @params     = params
    end

    def call
      plan = @membership.savings_plans.build(
        name:            @params[:name],
        monthly_amount:  @params[:monthly_amount],
        duration_months: @params[:duration_months],
        start_date:      @params[:start_date] || next_payroll_date,
        status:          :pending
      )

      return Result.failure(plan.errors.full_messages.join(", ")) unless plan.save

      notify_admins(plan)

      Notification.create!(
        user:       @membership.user,
        notifiable: plan,
        channel:    :in_app,
        event:      :savings_plan_submitted,
        sent:       true,
        sent_at:    Time.current
      )

      Result.success(plan)
    rescue => e
      Result.failure(e.message)
    end

    private

    def notify_admins(plan)
      @membership.company.hr_admins.each do |admin|
        PayrollAdminMailer.savings_plan_submitted(admin, plan).deliver_later

        Notification.create!(
          user:       admin,
          notifiable: plan,
          channel:    :email,
          event:      :savings_plan_submitted,
          sent:       true,
          sent_at:    Time.current
        )
      end
    end

    def next_payroll_date
      company   = @membership.company
      day       = company.payroll_day
      today     = Date.current
      candidate = today.change(day: day)
      candidate = candidate.next_month if candidate <= today
      candidate
    end
  end
end
