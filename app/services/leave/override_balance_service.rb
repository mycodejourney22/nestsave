module Leave
  class OverrideBalanceService
    def self.call(balance:, new_remaining:, admin:, reason: nil)
      new(balance, new_remaining, admin, reason).call
    end

    def initialize(balance, new_remaining, admin, reason)
      @balance       = balance
      @new_remaining = new_remaining.to_f
      @admin         = admin
      @reason        = reason
    end

    def call
      current_used = @balance.used_days
      new_accrued  = current_used + @new_remaining
      @balance.update!(
        accrued_days:  new_accrued,
        override_days: @new_remaining - (@balance.accrued_days - current_used),
        overridden_by: @admin.id,
        overridden_at: Time.current
      )
      Result.success(@balance)
    rescue => e
      Result.failure(e.message)
    end
  end
end
