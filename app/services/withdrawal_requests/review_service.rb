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
      approved = event == :withdrawal_approved
      plan     = @request.savings_plan
      NotificationService.create(
        user:     @request.user,
        company:  @request.company,
        title:    approved ? "Withdrawal approved" : "Withdrawal declined",
        body:     approved ? "#{@request.company.currency_symbol}#{'%.2f' % @request.amount.to_f} from #{plan.name} is on its way" : "Your withdrawal from #{plan.name} was not approved",
        link:     "/#{@request.company.slug}/employee/savings_plans/#{plan.id}",
        category: "savings",
        event:    event.to_s
      )
    end
  end
end
