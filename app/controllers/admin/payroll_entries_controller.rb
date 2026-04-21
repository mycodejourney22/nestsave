module Admin
  class PayrollEntriesController < ApplicationController
    before_action :require_hr!
    before_action :set_run
    before_action :set_entry

    def edit
      @earnings   = @entry.earnings_items
      @deductions = @entry.deductions_items
    end

    def update
      ActiveRecord::Base.transaction do
        # Update editable existing items
        if params[:payroll_items].present?
          params[:payroll_items].each do |id, item_params|
            item = @entry.payroll_items.editable.find_by(id: id)
            item&.update!(amount: item_params[:amount].to_s.gsub(",", "").to_f)
          end
        end

        # Add new bonus lines
        Array(params[:new_bonuses]).each do |bonus|
          next if bonus[:label].blank? || bonus[:amount].blank?
          @entry.payroll_items.create!(
            category:       "earning",
            item_type:      bonus[:item_type].presence || "other_bonus",
            label:          bonus[:label],
            amount:         bonus[:amount].to_s.gsub(",", "").to_f,
            auto_generated: false,
            editable:       true
          )
        end

        # Add new deduction lines
        Array(params[:new_deductions]).each do |ded|
          next if ded[:label].blank? || ded[:amount].blank?
          @entry.payroll_items.create!(
            category:       "deduction",
            item_type:      ded[:item_type].presence || "other_deduction",
            label:          ded[:label],
            amount:         ded[:amount].to_s.gsub(",", "").to_f,
            auto_generated: false,
            editable:       true
          )
        end

        @entry.recalculate!
      end

      redirect_to admin_payroll_run_path(@current_company.slug, @run),
                  notice: "Entry updated for #{@entry.display_name}."
    rescue => e
      redirect_to edit_admin_payroll_run_payroll_entry_path(@current_company.slug, @run, @entry),
                  alert: e.message
    end

    def destroy_item
      item = @entry.payroll_items.where(editable: true).find(params[:item_id])
      item.destroy!
      @entry.recalculate!
      redirect_to edit_admin_payroll_run_payroll_entry_path(@current_company.slug, @run, @entry),
                  notice: "Line removed."
    end

    private

    def set_run
      @run = @current_company.payroll_runs.find(params[:payroll_run_id])
    end

    def set_entry
      @entry = @run.payroll_entries.find(params[:id])
    end
  end
end
