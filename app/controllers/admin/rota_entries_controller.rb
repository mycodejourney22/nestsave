module Admin
  class RotaEntriesController < ApplicationController
    before_action :require_team_manager!
    before_action :set_rota

    def create
      @entry = @rota.rota_entries.build(entry_params)
      if @entry.save
        render json: { success: true, entry: entry_json(@entry) }
      else
        render json: { success: false, errors: @entry.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      @entry = @rota.rota_entries.find(params[:id])
      if @entry.update(entry_params)
        render json: { success: true, entry: entry_json(@entry) }
      else
        render json: { success: false, errors: @entry.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @entry = @rota.rota_entries.find(params[:id])
      @entry.destroy
      render json: { success: true }
    end

    private

    def set_rota
      @rota = Rota.joins(:team)
                  .where(teams: { company_id: @current_company.id })
                  .find(params[:rota_id])
    end

    def entry_params
      params.require(:rota_entry).permit(:employee_profile_id, :work_date, :start_time, :end_time, :notes)
    end

    def entry_json(entry)
      {
        id:                  entry.id,
        employee_profile_id: entry.employee_profile_id,
        work_date:           entry.work_date,
        start_time:          entry.start_time&.strftime("%H:%M"),
        end_time:            entry.end_time&.strftime("%H:%M"),
        notes:               entry.notes
      }
    end
  end
end
