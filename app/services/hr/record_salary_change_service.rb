module HR
  class RecordSalaryChangeService
    def self.call(profile:, new_amount:, reason:, effective_date:, changed_by:)
      new(profile, new_amount, reason, effective_date, changed_by).call
    end

    def initialize(profile, new_amount, reason, effective_date, changed_by)
      @profile        = profile
      @new_amount     = new_amount.to_d
      @reason         = reason
      @effective_date = effective_date
      @changed_by     = changed_by
    end

    def call
      if @new_amount <= 0
        return Result.failure("New salary amount must be greater than zero")
      end

      if @effective_date.blank?
        return Result.failure("Effective date is required")
      end

      entry = SalaryHistory.create!(
        employee_profile: @profile,
        amount:           @new_amount,
        currency:         "GBP",
        reason:           @reason,
        effective_date:   @effective_date,
        changed_by:       @changed_by.id
      )

      Result.success(entry)
    rescue => e
      Result.failure(e.message)
    end
  end
end
