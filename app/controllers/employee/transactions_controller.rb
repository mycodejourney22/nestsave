module Employee
  class TransactionsController < ApplicationController
    before_action :require_employee!

    def index
      @pagy, @transactions = pagy(
        @current_membership.transactions.order(created_at: :desc),
        limit: 20
      )
    end
  end
end
