module Admin
  class TeamsController < ApplicationController
    before_action :require_hr!
    before_action :set_team, only: [:show, :edit, :update, :destroy]

    def index
      @teams = @current_company.teams.kept.includes(:employee_profiles).order(:name)
    end

    def show
      @members = @team.employee_profiles
                      .where(deleted_at: nil)
                      .includes(company_membership: :user)
                      .order(:preferred_name, :employee_number)
    end

    def new
      @team = Team.new
    end

    def create
      @team = @current_company.teams.build(team_params)
      if @team.save
        redirect_to admin_teams_path(@current_company.slug), notice: "Team created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @team.update(team_params)
        redirect_to admin_teams_path(@current_company.slug), notice: "Team updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @team.employee_profiles.where(deleted_at: nil).exists?
        redirect_to admin_teams_path(@current_company.slug),
                    alert: "Cannot delete a team with active employees."
      else
        @team.soft_delete!
        redirect_to admin_teams_path(@current_company.slug), notice: "Team deleted."
      end
    end

    private

    def set_team
      @team = @current_company.teams.kept.find(params[:id])
    end

    def team_params
      params.require(:team).permit(:name, :description, :active)
    end
  end
end
