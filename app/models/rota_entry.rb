class RotaEntry < ApplicationRecord
  belongs_to :rota
  belongs_to :employee_profile

  validates :work_date, presence: true
  validates :employee_profile_id,
            uniqueness: { scope: [:rota_id, :work_date],
                         message: "already has a shift on this date" }
  validate  :work_date_within_rota_week

  def hours
    return nil unless start_time && end_time
    ((end_time - start_time) / 3600.0).round(1)
  end

  private

  def work_date_within_rota_week
    return unless work_date && rota
    unless (rota.week_start..rota.week_end).cover?(work_date)
      errors.add(:work_date,
        "must be within the rota week (#{rota.week_start} to #{rota.week_end})")
    end
  end
end
