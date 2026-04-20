module Payroll
  class MonthEndProcessor
    def self.call(company:)
      new(company).call
    end

    def initialize(company)
      @company = company
      @period  = Date.current.beginning_of_month
      @errors  = []
    end

    def call
      ActiveRecord::Base.transaction do
        process_savings_deductions
        process_advance_repayments
        check_matured_plans
      end

      Result.success({ errors: @errors })
    rescue => e
      Result.failure(e.message)
    end

    private

    def process_savings_deductions
      active_plans = SavingsPlan
        .joins(:company_membership)
        .where(company_memberships: { company_id: @company.id, status: "active" })
        .active

      active_plans.each do |plan|
        next if Transaction.where(reference: plan, period_month: @period, kind: :savings_deduction).exists?

        plan.update!(total_saved: plan.total_saved + plan.monthly_amount)

        Transaction.create!(
          company_membership: plan.company_membership,
          reference:          plan,
          kind:               :savings_deduction,
          amount:             plan.monthly_amount,
          status:             :completed,
          description:        "Monthly saving — #{plan.name}",
          period_month:       @period
        )

        EmployeeMailer.monthly_savings_confirmed(plan.user, plan).deliver_later

        Notification.create!(
          user:       plan.user,
          notifiable: plan,
          channel:    :in_app,
          event:      :monthly_savings_confirmed,
          sent:       true,
          sent_at:    Time.current
        )
      rescue => e
        @errors << { plan_id: plan.id, error: e.message }
      end
    end

    def process_advance_repayments
      due_schedules = AdvanceRepaymentSchedule
        .due_this_month
        .pending
        .joins(salary_advance: :company_membership)
        .where(salary_advances: { status: %w[disbursed repaying] })
        .where(company_memberships: { company_id: @company.id })

      due_schedules.each do |schedule|
        advance = schedule.salary_advance

        next if schedule.paid?

        schedule.update!(status: :paid, paid_at: Time.current)

        Transaction.create!(
          company_membership: advance.company_membership,
          reference:          advance,
          kind:               :advance_repayment,
          amount:             schedule.amount,
          status:             :completed,
          description:        "Advance repayment #{schedule.instalment_number}/#{advance.repayment_months}",
          period_month:       @period
        )

        advance.update!(status: :repaying) if advance.disbursed?

        if advance.fully_repaid?
          advance.update!(status: :settled)
          EmployeeMailer.advance_settled(advance.user, advance).deliver_later
          Notification.create!(
            user:       advance.user,
            notifiable: advance,
            channel:    :in_app,
            event:      :advance_settled,
            sent:       true,
            sent_at:    Time.current
          )
        else
          EmployeeMailer.advance_repayment_deducted(advance.user, advance, schedule).deliver_later
          Notification.create!(
            user:       advance.user,
            notifiable: advance,
            channel:    :in_app,
            event:      :advance_repayment_deducted,
            sent:       true,
            sent_at:    Time.current
          )
        end
      rescue => e
        @errors << { schedule_id: schedule.id, error: e.message }
      end
    end

    def check_matured_plans
      SavingsPlan
        .joins(:company_membership)
        .where(company_memberships: { company_id: @company.id })
        .active
        .where("maturity_date <= ?", Date.current)
        .each(&:mature!)
    end
  end
end
