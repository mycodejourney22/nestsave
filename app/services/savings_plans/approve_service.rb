module SavingsPlans
  class ApproveService
    def self.call(plan:, admin:, approved:, note: nil)
      new(plan, admin, approved, note).call
    end

    def initialize(plan, admin, approved, note)
      @plan     = plan
      @admin    = admin
      @approved = approved
      @note     = note
    end

    def call
      return Result.failure("Plan is not pending") unless @plan.pending?

      ActiveRecord::Base.transaction do
        if @approved
          @plan.update!(
            status:      :active,
            approved_by: @admin.id,
            approved_at: Time.current,
            notes:       @note
          )
          notify_employee(:savings_plan_approved)
          EmployeeMailer.savings_plan_approved(@plan.user, @plan).deliver_later
        else
          @plan.update!(status: :declined, notes: @note, approved_by: @admin.id, approved_at: Time.current)
          notify_employee(:savings_plan_declined)
          EmployeeMailer.savings_plan_declined(@plan.user, @plan, @note).deliver_later
        end
      end

      Result.success(@plan)
    rescue => e
      Result.failure(e.message)
    end

    private

    def notify_employee(event)
      Notification.create!(
        user:       @plan.user,
        notifiable: @plan,
        channel:    :in_app,
        event:      event,
        sent:       true,
        sent_at:    Time.current
      )
    end
  end
end
