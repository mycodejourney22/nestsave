module Payroll
  class CreateRunService
    def self.call(company:, month:, year:, created_by:)
      new(company, month, year, created_by).call
    end

    def initialize(company, month, year, created_by)
      @company    = company
      @month      = month
      @year       = year
      @created_by = created_by
      @period     = Date.new(year, month, 1)
    end

    def call
      ActiveRecord::Base.transaction do
        run = PayrollRun.create!(
          company:    @company,
          month:      @month,
          year:       @year,
          status:     :draft,
          created_by: @created_by.id
        )

        active_memberships.each do |membership|
          build_entry(run, membership)
        end

        Result.success(run)
      end
    rescue => e
      Result.failure(e.message)
    end

    private

    def active_memberships
      @company.company_memberships
              .active
              .where(role: "employee")
              .includes(:employee_profile, :salary_advances, :savings_plans)
    end

    def build_entry(run, membership)
      profile = membership.employee_profile
      return unless profile

      salary = profile.current_salary || 0

      entry = run.payroll_entries.create!(
        employee_profile: profile,
        base_salary:      salary,
        total_earnings:   0,
        total_deductions: 0,
        net_pay:          0
      )

      # Base salary — always first, auto, locked
      entry.payroll_items.create!(
        category:       "earning",
        item_type:      "base_salary",
        label:          "Base salary",
        amount:         salary,
        auto_generated: true,
        editable:       false
      )

      # PAYE — pre-filled from last month (0 for first run)
      last_paye = last_month_item(profile, "paye")
      entry.payroll_items.create!(
        category:       "deduction",
        item_type:      "paye",
        label:          "PAYE tax",
        amount:         last_paye&.amount || 0,
        auto_generated: false,
        editable:       true
      )

      # Pension — pre-filled from last month (0 for first run)
      last_pension = last_month_item(profile, "pension")
      entry.payroll_items.create!(
        category:       "deduction",
        item_type:      "pension",
        label:          "Pension",
        amount:         last_pension&.amount || 0,
        auto_generated: false,
        editable:       true
      )

      # Auto-generate savings deductions
      membership.savings_plans.active.each do |plan|
        entry.payroll_items.create!(
          category:       "deduction",
          item_type:      "savings",
          label:          "NestSave savings — #{plan.name}",
          amount:         plan.monthly_amount,
          auto_generated: true,
          editable:       false
        )
      end

      # Auto-generate advance repayments due this month
      AdvanceRepaymentSchedule
        .due_this_month
        .pending
        .joins(:salary_advance)
        .where(salary_advances: {
          company_membership_id: membership.id,
          status:                %w[disbursed repaying]
        })
        .each do |schedule|
          entry.payroll_items.create!(
            category:       "deduction",
            item_type:      "advance_repayment",
            label:          "Salary advance repayment " \
                            "#{schedule.instalment_number}/" \
                            "#{schedule.salary_advance.repayment_months}",
            amount:         schedule.amount,
            auto_generated: true,
            editable:       false
          )
        end

      entry.recalculate!
    end

    def last_month_item(profile, item_type)
      last_run = @company.payroll_runs
                         .where(
                           "(year = ? AND month < ?) OR year < ?",
                           @year, @month, @year
                         )
                         .order(year: :desc, month: :desc)
                         .first
      return nil unless last_run

      last_run.payroll_entries
              .find_by(employee_profile: profile)
              &.payroll_items
              &.find_by(item_type: item_type)
    end
  end
end
