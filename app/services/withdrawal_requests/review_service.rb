module WithdrawalRequests
  class ReviewService
    def self.call(request:, admin:, approved:, note: nil)
      new(request, admin, approved, note).call
    end

    def initialize(request, admin, approved, note)
      @request  = request
      @admin    = admin
      @approved = approved
      @note     = note
    end

    def call
      return Result.failure("Request is not pending") unless @request.pending?

      ActiveRecord::Base.transaction do
        if @approved
          @request.update!(
            status:      :approved,
            reviewed_by: @admin.id,
            reviewed_at: Time.current,
            review_note: @note
          )

          plan = @request.savings_plan
          plan.update!(total_saved: plan.total_saved - @request.amount)

          Transaction.create!(
            company_membership: @request.company_membership,
            reference:          plan,
            kind:               :savings_withdrawal,
            amount:             @request.amount,
            status:             :completed,
            description:        "Withdrawal from #{plan.name}",
            period_month:       Date.current.beginning_of_month
          )

          EmployeeMailer.withdrawal_approved(@request.user, @request).deliver_later
          notify_employee(:withdrawal_approved)
        else
          @request.update!(
            status:      :declined,
            reviewed_by: @admin.id,
            reviewed_at: Time.current,
            review_note: @note
          )
          EmployeeMailer.withdrawal_declined(@request.user, @request, @note).deliver_later
          notify_employee(:withdrawal_declined)
        end
      end

      Result.success(@request)
    rescue => e
      Result.failure(e.message)
    end

    private

    def notify_employee(event)
      Notification.create!(
        user:       @request.user,
        notifiable: @request,
        channel:    :in_app,
        event:      event,
        sent:       true,
        sent_at:    Time.current
      )
    end
  end
end
