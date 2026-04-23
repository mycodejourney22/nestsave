module SalaryAdvances
  class ReviewService
    def self.call(advance:, admin:, approved:, note: nil)
      new(advance, admin, approved, note).call
    end

    def initialize(advance, admin, approved, note)
      @advance  = advance
      @admin    = admin
      @approved = approved
      @note     = note
    end

    def call
      return Result.failure("Advance is not pending") unless @advance.pending?

      ActiveRecord::Base.transaction do
        if @approved
          @advance.update!(
            status:      :approved,
            reviewed_by: @admin.id,
            reviewed_at: Time.current,
            review_note: @note
          )

          generate_repayment_schedule!
          EmployeeMailer.advance_approved(@advance.user, @advance).deliver_later
          notify_employee(:advance_approved)
        else
          @advance.update!(
            status:      :declined,
            reviewed_by: @admin.id,
            reviewed_at: Time.current,
            review_note: @note
          )
          EmployeeMailer.advance_declined(@advance.user, @advance, @note).deliver_later
          notify_employee(:advance_declined)
        end
      end

      Result.success(@advance)
    rescue => e
      Result.failure(e.message)
    end

    private

    def generate_repayment_schedule!
      company   = @advance.company
      today     = Date.current
      start_day = company.payroll_day

      base_date = today.change(day: start_day)
      base_date = base_date.next_month if base_date <= today

      @advance.repayment_months.times do |i|
        due = base_date + i.months
        @advance.advance_repayment_schedules.create!(
          instalment_number: i + 1,
          amount:            @advance.monthly_instalment,
          due_date:          due,
          status:            :pending
        )
      end
    end

    def notify_employee(event)
      approved = event == :advance_approved
      NotificationService.create(
        user:     @advance.user,
        company:  @advance.company,
        title:    approved ? "Advance request approved" : "Advance request declined",
        body:     approved ? "Your advance will be disbursed shortly" : "Your advance request was not approved",
        link:     "/#{@advance.company.slug}/employee/salary_advances/#{@advance.id}",
        category: "advance",
        event:    event.to_s
      )
    end
  end
end
