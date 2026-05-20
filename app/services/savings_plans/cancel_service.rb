module SavingsPlans
  class CancelService
    def self.call(plan:, admin:, note: nil)
      new(plan, admin, note).call
    end

    def initialize(plan, admin, note)
      @plan  = plan
      @admin = admin
      @note  = note
    end

    def call
      return Result.failure("Only active plans can be cancelled") unless @plan.active?

      ActiveRecord::Base.transaction do
        @plan.update!(
          status:      :cancelled,
          approved_by: @admin.id,
          approved_at: Time.current,
          notes:       @note
        )
        notify_employee
        EmployeeMailer.savings_plan_cancelled(@plan.user, @plan, @note).deliver_later
      end

      Result.success(@plan)
    rescue => e
      Result.failure(e.message)
    end

    private

    def notify_employee
      NotificationService.create(
        user:     @plan.user,
        company:  @plan.company,
        title:    "Savings plan cancelled",
        body:     "Your \"#{@plan.name}\" plan has been cancelled. Please contact HR regarding your refund of #{format_amount(@plan.total_saved)}.",
        link:     "/#{@plan.company.slug}/employee/savings_plans/#{@plan.id}",
        category: "savings",
        event:    "savings_plan_cancelled"
      )
    end

    def format_amount(amount)
      "£#{"%.2f" % amount}"
    end
  end
end
