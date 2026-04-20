ActiveRecord::Base.transaction do

  company = Company.create!(
    name:            "Acme Technologies Ltd",
    slug:            "acmetech",
    payroll_email:   "payroll@acmetech.co.uk",
    timezone:        "London",
    payroll_day:     25,
    active:          true,
    country:         "United Kingdom",
    currency:        "GBP",
    currency_symbol: "£"
  )

  # ── Departments ───────────────────────────────────────────────────────────
  engineering  = Department.create!(company: company, name: "Engineering",  color: "#1D9E75")
  finance      = Department.create!(company: company, name: "Finance",       color: "#3B82F6")
  _hr_dept     = Department.create!(company: company, name: "People & HR",   color: "#8B5CF6")
  _product     = Department.create!(company: company, name: "Product",       color: "#F59E0B")

  # ── Admin ─────────────────────────────────────────────────────────────────
  admin_user = User.create!(
    full_name: "Hannah Moore",
    email:     "admin@acmetech.co.uk",
    password:  "password123"
  )

  admin_membership = CompanyMembership.create!(
    user:      admin_user,
    company:   company,
    role:      :super_admin,
    status:    :active,
    joined_at: Time.current
  )

  HR::CreateEmployeeProfileService.call(
    membership:     admin_membership,
    profile_params: {
      job_title:             "Head of Finance",
      department_id:         finance.id,
      employment_type:       "full_time",
      employment_start_date: Date.new(2020, 1, 6)
    },
    initial_salary: 6000,
    current_admin:  admin_user
  )

  # ── Employee (Seun) ───────────────────────────────────────────────────────
  employee_user = User.create!(
    full_name: "Oluwaseun Adeyemi",
    email:     "seun@acmetech.co.uk",
    password:  "password123"
  )

  seun_membership = CompanyMembership.create!(
    user:       employee_user,
    company:    company,
    role:       :employee,
    status:     :active,
    invited_by: admin_user.id,
    joined_at:  Time.current
  )

  seun_profile_result = HR::CreateEmployeeProfileService.call(
    membership:     seun_membership,
    profile_params: {
      job_title:             "Software Engineer",
      department_id:         engineering.id,
      employment_type:       "full_time",
      employment_start_date: Date.new(2022, 3, 1),
      phone:                 "+44 7700 900123",
      nationality:           "Nigerian",
      date_of_birth:         Date.new(1992, 8, 14),
      address_line_1:        "42 Maple Street",
      city:                  "London",
      postcode:              "E1 6RF",
      country:               "United Kingdom",
      right_to_work_status:  "British Citizen"
    },
    initial_salary: 3800,
    current_admin:  admin_user
  )

  seun_profile = seun_profile_result.value

  # Additional salary history entries for Seun
  HR::RecordSalaryChangeService.call(
    profile:        seun_profile,
    new_amount:     4200,
    reason:         "Annual review",
    effective_date: Date.new(2023, 3, 1),
    changed_by:     admin_user
  )

  HR::RecordSalaryChangeService.call(
    profile:        seun_profile,
    new_amount:     4500,
    reason:         "Promotion",
    effective_date: Date.new(2024, 6, 1),
    changed_by:     admin_user
  )

  # Emergency contact for Seun
  EmergencyContact.create!(
    employee_profile: seun_profile,
    full_name:        "Aduke Adeyemi",
    relationship:     "Spouse",
    phone:            "+44 7700 900456",
    email:            "aduke@example.com",
    primary:          true
  )

  # Reference for Seun
  EmployeeReference.create!(
    employee_profile: seun_profile,
    referee_name:     "Dr. Chibuike Okafor",
    organisation:     "Lagos Tech Partners",
    relationship:     "Previous manager",
    email:            "chibuike@ltpartners.ng",
    status:           "received",
    requested_on:     Date.new(2022, 2, 14),
    received_on:      Date.new(2022, 2, 28)
  )

  # ── Teams ─────────────────────────────────────────────────────────────────
  eng_team = Team.create!(
    company:     company,
    name:        "Engineering",
    description: "Product engineers and platform team",
    active:      true
  )

  Team.create!(
    company:     company,
    name:        "Operations",
    description: "Finance, HR and business operations",
    active:      true
  )

  # Assign Seun to Engineering team
  seun_profile.update!(team: eng_team)

  # ── Leave types ────────────────────────────────────────────────────────────
  annual_leave = LeaveType.create!(
    company:         company,
    name:            "Annual Leave",
    category:        :annual,
    default_days:    21,
    requires_balance: true,
    accrues_monthly: true,
    active:          true
  )

  LeaveType.create!(
    company:         company,
    name:            "Sick Leave",
    category:        :sick,
    default_days:    0,
    requires_balance: false,
    accrues_monthly: false,
    active:          true
  )

  LeaveType.create!(
    company:         company,
    name:            "Maternity Leave",
    category:        :maternity,
    default_days:    90,
    requires_balance: true,
    accrues_monthly: false,
    active:          true
  )

  # ── Leave balance for Seun (current year, pro-rated) ──────────────────────
  months_worked = Date.current.month
  accrued = (annual_leave.default_days.to_f / 12 * months_worked).round(1)

  LeaveBalance.create!(
    employee_profile: seun_profile,
    leave_type:       annual_leave,
    year:             Date.current.year,
    total_days:       annual_leave.default_days,
    accrued_days:     accrued,
    used_days:        0,
    override_days:    0
  )

  puts "Seeded: #{company.name}"
  puts "  Currency: #{company.currency_symbol} (#{company.currency})"
  puts "  Depts:    #{Department.where(company: company).pluck(:name).join(", ")}"
  puts "  Admin:    #{admin_user.email} / password123"
  puts "  Employee: #{employee_user.email} / password123"
  puts "  URL base: /acmetech/"

end
