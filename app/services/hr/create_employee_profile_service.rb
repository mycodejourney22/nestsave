module HR
  class CreateEmployeeProfileService
    def self.call(membership:, profile_params:, initial_salary:, current_admin:)
      new(membership, profile_params, initial_salary, current_admin).call
    end

    def initialize(membership, profile_params, initial_salary, current_admin)
      @membership      = membership
      @profile_params  = profile_params
      @initial_salary  = initial_salary.to_d
      @current_admin   = current_admin
    end

    def call
      ActiveRecord::Base.transaction do
        profile = @membership.build_employee_profile(@profile_params)

        unless profile.save
          return Result.failure(profile.errors.full_messages.join(", "))
        end

        SalaryHistory.create!(
          employee_profile: profile,
          amount:           @initial_salary,
          currency:         "GBP",
          reason:           "Starting salary",
          effective_date:   profile.employment_start_date,
          changed_by:       @current_admin.id
        )

        Result.success(profile)
      end
    rescue => e
      Result.failure(e.message)
    end
  end
end
