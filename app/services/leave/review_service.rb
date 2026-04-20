module Leave
  class ReviewService
    def self.call(request:, reviewer:, approved:, note: nil)
      new(request, reviewer, approved, note).call
    end

    def initialize(request, reviewer, approved, note)
      @request  = request
      @reviewer = reviewer
      @approved = approved
      @note     = note
    end

    def call
      return Result.failure("Not pending") unless @request.pending?
      ActiveRecord::Base.transaction do
        if @approved
          @request.update!(
            status:      :approved,
            reviewed_by: @reviewer.id,
            reviewed_at: Time.current,
            review_note: @note
          )
          deduct_balance if @request.leave_balance
          EmployeeMailer.leave_approved(@request.user, @request).deliver_later
        else
          @request.update!(
            status:      :declined,
            reviewed_by: @reviewer.id,
            reviewed_at: Time.current,
            review_note: @note
          )
          EmployeeMailer.leave_declined(@request.user, @request, @note).deliver_later
        end
      end
      Result.success(@request)
    rescue => e
      Result.failure(e.message)
    end

    private

    def deduct_balance
      @request.leave_balance.increment!(:used_days, @request.total_days)
    end
  end
end
