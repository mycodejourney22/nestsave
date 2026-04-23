module Leave
  class RequestService
    def self.call(profile:, leave_type:, params:)
      new(profile, leave_type, params).call
    end

    def initialize(profile, leave_type, params)
      @profile    = profile
      @leave_type = leave_type
      @params     = params
    end

    def call
      ActiveRecord::Base.transaction do
        balance = find_or_create_balance
        request = @profile.leave_requests.build(
          leave_type:    @leave_type,
          leave_balance: balance,
          start_date:    @params[:start_date],
          end_date:      @params[:end_date],
          reason:        @params[:reason],
          status:        :pending,
          requested_at:  Time.current
        )
        return Result.failure(request.errors.full_messages.join(", ")) unless request.save
        notify_reviewers(request)
        Result.success(request)
      end
    rescue => e
      Result.failure(e.message)
    end

    private

    def find_or_create_balance
      return nil unless @leave_type.requires_balance?
      @profile.leave_balances.find_or_create_by!(
        leave_type: @leave_type,
        year:       Date.current.year
      ) do |b|
        b.total_days   = @leave_type.default_days
        b.accrued_days = accrued_so_far
      end
    end

    def accrued_so_far
      return 0 unless @leave_type.accrues_monthly?
      months_worked = [
        (Date.current.year * 12 + Date.current.month) -
        (@profile.employment_start_date.year * 12 + @profile.employment_start_date.month),
        Date.current.month
      ].min
      (months_worked * @leave_type.default_days / 12.0).round(1)
    end

    def notify_reviewers(request)
      reviewers = @profile.company.company_memberships
                    .active
                    .where(role: %w[hr_admin super_admin])
                    .includes(:user)

      if @profile.team
        team_managers = @profile.company.company_memberships
                          .active
                          .where(role: "team_manager", team_id: @profile.team_id)
                          .includes(:user)
        reviewers = reviewers.or(team_managers)
      end

      reviewers.each do |m|
        PayrollMailer.leave_requested(m.user, request).deliver_later
        NotificationService.create(
          user:     m.user,
          company:  @profile.company,
          title:    "New leave request",
          body:     "#{@profile.full_name || "An employee"} requested #{request.total_days} day(s) of #{request.leave_type.name}",
          link:     "/#{@profile.company.slug}/admin/leave_requests",
          category: "leave",
          event:    "leave_requested"
        )
      end
    end
  end
end
