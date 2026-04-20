class ScheduleMonthEndJobsJob < ApplicationJob
  queue_as :scheduler

  def perform
    today = Date.current.day
    Company.active.where(payroll_day: today).find_each do |company|
      MonthEndJob.perform_later(company.id.to_s)
    end
  end
end
