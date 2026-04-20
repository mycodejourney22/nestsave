module SalaryAdvances
  class DisburseService
    def self.call(advance:, admin:)
      new(advance, admin).call
    end

    def initialize(advance, admin)
      @advance = advance
      @admin   = admin
    end

    def call
      return Result.failure("Advance must be approved before disbursement") unless @advance.approved?

      ActiveRecord::Base.transaction do
        @advance.update!(status: :disbursed, disbursed_at: Time.current)

        Transaction.create!(
          company_membership: @advance.company_membership,
          reference:          @advance,
          kind:               :advance_disbursement,
          amount:             @advance.amount,
          status:             :completed,
          description:        "Salary advance disbursed",
          period_month:       Date.current.beginning_of_month
        )

        EmployeeMailer.advance_disbursed(@advance.user, @advance).deliver_later

        Notification.create!(
          user:       @advance.user,
          notifiable: @advance,
          channel:    :in_app,
          event:      :advance_disbursed,
          sent:       true,
          sent_at:    Time.current
        )
      end

      Result.success(@advance)
    rescue => e
      Result.failure(e.message)
    end
  end
end
