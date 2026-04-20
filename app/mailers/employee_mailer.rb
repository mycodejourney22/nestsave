class EmployeeMailer < ApplicationMailer
  def savings_plan_approved(user, plan)
    @user        = user
    @plan        = plan
    @company     = plan.company_membership.company
    @plan_url    = employee_savings_plan_url(company_slug: @company.slug, id: plan.id)

    mail to:      user.email,
         subject: "[NestSave] Your savings plan \"#{plan.name}\" is now active"
  end

  def savings_plan_declined(user, plan, note)
    @user     = user
    @plan     = plan
    @note     = note
    @company  = plan.company_membership.company
    @new_url  = new_employee_savings_plan_url(company_slug: @company.slug)

    mail to:      user.email,
         subject: "[NestSave] Update on your savings plan \"#{plan.name}\""
  end

  def monthly_savings_confirmed(user, plan)
    @user     = user
    @plan     = plan
    @company  = plan.company_membership.company
    @plan_url = employee_savings_plan_url(company_slug: @company.slug, id: plan.id)

    mail to:      user.email,
         subject: "[NestSave] #{formatted_currency(plan.monthly_amount)} saved this month — #{plan.name}"
  end

  def withdrawal_approved(user, request)
    @user      = user
    @request   = request
    @plan      = request.savings_plan
    @company   = request.company_membership.company
    @plans_url = employee_savings_plans_url(company_slug: @company.slug)

    mail to:      user.email,
         subject: "[NestSave] Withdrawal approved — #{formatted_currency(request.amount)} from #{@plan.name}"
  end

  def withdrawal_declined(user, request, note)
    @user      = user
    @request   = request
    @note      = note
    @plan      = request.savings_plan
    @company   = request.company_membership.company
    @plans_url = employee_savings_plans_url(company_slug: @company.slug)

    mail to:      user.email,
         subject: "[NestSave] Update on your withdrawal request"
  end

  def advance_approved(user, advance)
    @user       = user
    @advance    = advance
    @company    = advance.company_membership.company
    @advance_url = employee_salary_advance_url(company_slug: @company.slug, id: advance.id)
    @schedules  = advance.advance_repayment_schedules.order(:instalment_number)

    mail to:      user.email,
         subject: "[NestSave] Salary advance approved — #{formatted_currency(advance.amount)}"
  end

  def advance_declined(user, advance, note)
    @user        = user
    @advance     = advance
    @note        = note
    @company     = advance.company_membership.company
    @advances_url = employee_salary_advances_url(company_slug: @company.slug)

    mail to:      user.email,
         subject: "[NestSave] Update on your salary advance request"
  end

  def advance_disbursed(user, advance)
    @user        = user
    @advance     = advance
    @company     = advance.company_membership.company
    @advance_url = employee_salary_advance_url(company_slug: @company.slug, id: advance.id)
    @schedules   = advance.advance_repayment_schedules.order(:instalment_number)

    mail to:      user.email,
         subject: "[NestSave] Your salary advance of #{formatted_currency(advance.amount)} has been sent"
  end

  def advance_repayment_deducted(user, advance, schedule)
    @user        = user
    @advance     = advance
    @schedule    = schedule
    @company     = advance.company_membership.company
    @advance_url = employee_salary_advance_url(company_slug: @company.slug, id: advance.id)
    @next        = advance.advance_repayment_schedules
                          .where(status: "pending")
                          .order(:instalment_number)
                          .first

    mail to:      user.email,
         subject: "[NestSave] Advance repayment #{schedule.instalment_number}/#{advance.repayment_months} deducted — #{formatted_currency(schedule.amount)}"
  end

  def advance_settled(user, advance)
    @user         = user
    @advance      = advance
    @company      = advance.company_membership.company
    @advances_url = employee_salary_advances_url(company_slug: @company.slug)

    mail to:      user.email,
         subject: "[NestSave] Salary advance fully repaid — well done!"
  end

  private

  def formatted_currency(amount)
    "£#{'%.2f' % amount.to_f}"
  end
end
