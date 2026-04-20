module Employee
  class RotasController < ApplicationController
    before_action :require_employee!
    before_action :set_profile

    def index
      if @profile.team
        @rotas = @profile.team.rotas.published.recent
        @current_rota = @rotas.find { |r| (r.week_start..r.week_end).cover?(Date.current) }
      else
        @rotas = []
      end
    end

    def show
      @rota = Rota.published
                  .joins(:team)
                  .where(teams: { company_id: @current_company.id })
                  .find(params[:id])
      @my_entries = @rota.rota_entries.where(employee_profile: @profile)
      @days = (@rota.week_start..@rota.week_end).to_a
    end

    private

    def set_profile
      @profile = @current_membership.employee_profile
    end
  end
end
