class MonthEndJob < ApplicationJob
  queue_as :payroll

  def perform(company_id)
    company = Company.find(company_id)
    return unless company.active?

    Rails.logger.info "[MonthEndJob] Processing #{company.name} for #{Date.current.strftime('%B %Y')}"

    result = Payroll::MonthEndProcessor.call(company: company)

    if result.failure?
      Rails.logger.error "[MonthEndJob] Failed for #{company.name}: #{result.error}"
      raise result.error
    end

    if result.value[:errors].any?
      Rails.logger.warn "[MonthEndJob] Completed with errors for #{company.name}: #{result.value[:errors]}"
    else
      Rails.logger.info "[MonthEndJob] Successfully processed #{company.name}"
    end
  end
end
