module Employee
  class ProfilesController < ApplicationController
    before_action :require_employee!

    def show
      @profile              = @current_membership.employee_profile
      @salary_history       = @profile&.salary_histories&.order(effective_date: :desc) || []
      @emergency_contacts   = @profile&.emergency_contacts&.order(created_at: :asc) || []
      @bank_detail          = @profile&.bank_details&.find_by(active: true)
      @employment_histories = @profile&.employment_histories&.ordered || []
      @documents            = @profile&.documents&.kept&.order(created_at: :desc) || []
    end
  end
end
