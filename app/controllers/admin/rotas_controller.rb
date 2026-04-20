module Admin
  class RotasController < ApplicationController
    before_action :require_team_manager!
    before_action :set_rota, only: [:show, :publish]

    def index
      teams = if @current_membership.hr_or_above?
                @current_company.teams.active
              else
                @current_company.teams.active.where(id: @current_membership.team_id)
              end
      @rotas = Rota.where(team: teams).includes(:team).recent.limit(50)
      @teams = teams
    end

    def new
      @teams     = available_teams
      @team      = @teams.first
      @week_start = beginning_of_week(params[:week_start] ? Date.parse(params[:week_start]) : Date.current)
      @rota = Rota.new(team: @team, week_start: @week_start)
    end

    def create
      team = @current_company.teams.active.find(rota_params[:team_id])
      week_start = Date.parse(rota_params[:week_start])
      @rota = Rota.new(
        team:       team,
        created_by: current_user.id,
        week_start: week_start,
        week_end:   week_start + 6.days,
        status:     :draft
      )
      if @rota.save
        redirect_to admin_rota_path(@current_company.slug, @rota), notice: "Rota created."
      else
        @teams = available_teams
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @entries = @rota.rota_entries
                      .includes(:employee_profile)
                      .group_by { |e| e.employee_profile_id }
      @members = @rota.team.employee_profiles
                      .where(deleted_at: nil)
                      .includes(:company_membership)
      @days = (@rota.week_start..@rota.week_end).to_a
    end

    def publish
      if @rota.publish!
        @rota.team.employee_profiles.each do |profile|
          EmployeeMailer.rota_published(profile.user, @rota).deliver_later if profile.user
        end
        redirect_to admin_rota_path(@current_company.slug, @rota), notice: "Rota published."
      else
        redirect_to admin_rota_path(@current_company.slug, @rota), alert: "Could not publish rota."
      end
    end

    private

    def set_rota
      @rota = Rota.joins(:team)
                  .where(teams: { company_id: @current_company.id })
                  .find(params[:id])
    end

    def available_teams
      if @current_membership.hr_or_above?
        @current_company.teams.active
      else
        @current_company.teams.active.where(id: @current_membership.team_id)
      end
    end

    def beginning_of_week(date)
      date - ((date.wday - 1) % 7)
    end

    def rota_params
      params.require(:rota).permit(:team_id, :week_start)
    end
  end
end
