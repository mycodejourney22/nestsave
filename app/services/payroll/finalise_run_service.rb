module Payroll
  class FinaliseRunService
    def self.call(run:, admin:)
      new(run, admin).call
    end

    def initialize(run, admin)
      @run   = run
      @admin = admin
    end

    def call
      return Result.failure("Already finalised") if @run.payslips_sent?

      ActiveRecord::Base.transaction do
        @run.recalculate_totals!
        @run.update!(
          status:       :finalised,
          finalised_by: @admin.id,
          finalised_at: Time.current
        )
        Result.success(@run)
      end
    rescue => e
      Result.failure(e.message)
    end
  end
end
