module Payroll
  class ReopenRunService
    def self.call(run:, admin:)
      new(run, admin).call
    end

    def initialize(run, admin)
      @run   = run
      @admin = admin
    end

    def call
      return Result.failure("Cannot reopen — payslips already sent") if @run.payslips_sent?

      @run.update!(
        status:       :draft,
        finalised_by: nil,
        finalised_at: nil
      )
      Result.success(@run)
    rescue => e
      Result.failure(e.message)
    end
  end
end
