module Leave
  class ManagerReviewService
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
            status:              :manager_approved,
            manager_reviewed_by: @reviewer.id,
            manager_reviewed_at: Time.current
          )
          notify_hr
        else
          @request.update!(
            status:              :declined,
            manager_reviewed_by: @reviewer.id,
            manager_reviewed_at: Time.current,
            review_note:         @note
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

    def notify_hr
      hr_admins = @request.company.company_memberships
                    .active
                    .where(role: %w[hr_admin super_admin])
                    .includes(:user)

      hr_admins.each do |m|
        PayrollMailer.leave_requested(m.user, @request).deliver_later
        NotificationService.create(
          user:     m.user,
          company:  @request.company,
          title:    "Leave request awaiting your approval",
          body:     "#{@request.employee_profile.full_name || "An employee"}'s #{@request.leave_type.name} request was approved by their manager and needs your final approval",
          link:     "/#{@request.company.slug}/admin/leave_requests",
          category: "leave",
          event:    "leave_requested"
        )
      end
    end
  end
end
