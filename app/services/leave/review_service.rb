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
          NotificationService.create(
            user:     @request.user,
            company:  @request.company,
            title:    "Leave request approved",
            body:     "Your #{@request.leave_type.name} request has been approved",
            link:     "/#{@request.company.slug}/employee/leave_requests",
            category: "leave",
            event:    "leave_approved"
          )
        else
          @request.update!(
            status:      :declined,
            reviewed_by: @reviewer.id,
            reviewed_at: Time.current,
            review_note: @note
          )
          EmployeeMailer.leave_declined(@request.user, @request, @note).deliver_later
          NotificationService.create(
            user:     @request.user,
            company:  @request.company,
            title:    "Leave request declined",
            body:     "Your #{@request.leave_type.name} request was not approved",
            link:     "/#{@request.company.slug}/employee/leave_requests",
            category: "leave",
            event:    "leave_declined"
          )
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
