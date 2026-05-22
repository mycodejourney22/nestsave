module SalaryAdvances
  class AmendService
    def self.call(advance:, admin:, amount:, repayment_months:, note: nil)
      new(advance, admin, amount, repayment_months, note).call
    end

    def initialize(advance, admin, amount, repayment_months, note)
      @advance          = advance
      @admin            = admin
      @amount           = amount.to_d
      @repayment_months = repayment_months.to_i
      @note             = note
    end

    def call
      unless @advance.pending? || @advance.approved?
        return Result.failure("Only pending or approved advances can be amended")
      end

      ActiveRecord::Base.transaction do
        # Drop any unpaid instalments so they can be regenerated
        @advance.advance_repayment_schedules.where(status: :pending).destroy_all

        @advance.assign_attributes(
          amount:           @amount,
          repayment_months: @repayment_months,
          review_note:      @note.presence || @advance.review_note
        )

        unless @advance.save
          raise ActiveRecord::Rollback, @advance.errors.full_messages.to_sentence
        end

        # Regenerate schedule if already approved (pending has no schedule yet)
        regenerate_schedule! if @advance.approved?

        notify_employee
      end

      Result.success(@advance)
    rescue ActiveRecord::Rollback => e
      Result.failure(e.message)
    rescue => e
      Result.failure(e.message)
    end

    private

    def regenerate_schedule!
      company   = @advance.company
      today     = Date.current
      start_day = company.payroll_day

      base_date = today.change(day: start_day)
      base_date = base_date.next_month if base_date <= today

      @advance.repayment_months.times do |i|
        @advance.advance_repayment_schedules.create!(
          instalment_number: i + 1,
          amount:            @advance.monthly_instalment,
          due_date:          base_date + i.months,
          status:            :pending
        )
      end
    end

    def notify_employee
      NotificationService.create(
        user:     @advance.user,
        company:  @advance.company,
        title:    "Salary advance updated",
        body:     "Your advance has been amended to #{@advance.company.currency_symbol}#{"%.2f" % @advance.amount} over #{@advance.repayment_months} months",
        link:     "/#{@advance.company.slug}/employee/salary_advances/#{@advance.id}",
        category: "advance",
        event:    "advance_amended"
      )
    end
  end
end
