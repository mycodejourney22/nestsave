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
      @team  = Team.new
      @staff = @current_company.company_memberships.active.includes(:user).order("users.full_name")
    end

    def create
      @team = @current_company.teams.build(team_params)
      if @team.save
        assign_manager(@team, params[:team][:manager_membership_id])
        redirect_to admin_teams_path(@current_company.slug), notice: "Team created."
      else
        @staff = @current_company.company_memberships.active.includes(:user).order("users.full_name")
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @staff = @current_company.company_memberships.active.includes(:user).order("users.full_name")
    end

    def update
      if @team.update(team_params)
        assign_manager(@team, params[:team][:manager_membership_id])
        redirect_to admin_teams_path(@current_company.slug), notice: "Team updated."
      else
        @staff = @current_company.company_memberships.active.includes(:user).order("users.full_name")
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

    def assign_manager(team, membership_id)
      existing = @current_company.company_memberships.active.team_manager.find_by(team_id: team.id)
      if existing && existing.id != membership_id
        existing.update!(team_id: nil, role: :employee)
      end

      return if membership_id.blank?

      membership = @current_company.company_memberships.active.find(membership_id)
      if membership.employee?
        membership.update!(team_id: team.id, role: :team_manager)
      else
        membership.update!(team_id: team.id)
      end
    end
  end
end
