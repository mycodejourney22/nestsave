module Payroll
  class SendPayslipsService
    def self.call(run:, admin:)
      new(run, admin).call
    end

    def initialize(run, admin)
      @run   = run
      @admin = admin
    end

    def call
      return Result.failure("Must be finalised before sending payslips") unless @run.finalised?

      ActiveRecord::Base.transaction do
        @run.payroll_entries
            .includes(employee_profile: { company_membership: :user })
            .each do |entry|
          user = entry.employee_profile.company_membership.user
          next unless user
          EmployeeMailer.payslip_ready(user, entry).deliver_later
          NotificationService.create(
            user:     user,
            company:  @run.company,
            title:    "Your #{@run.period_label} payslip is ready",
            body:     "Net pay: #{@run.company.currency_symbol}#{'%.2f' % entry.net_pay}",
            link:     "/#{@run.company.slug}/employee/payslips",
            category: "payroll",
            event:    "payslip_ready"
          )
        end

        @run.update!(
          status:           :payslips_sent,
          payslips_sent_at: Time.current
        )

        # Month-end processing (advance repayments, savings) handled separately
      end

      Result.success(@run)
    rescue => e
      Result.failure(e.message)
    end
  end
end
