module Employee
  class DocumentsController < ApplicationController
    before_action :require_employee!

    def index
      @profile   = @current_membership.employee_profile
      @documents = @profile&.documents&.kept&.order(created_at: :desc) || []
    end
  end
end
