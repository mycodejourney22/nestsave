# Clean-up tasks for the November 2026 sign-up bot incident.
#
#   bin/rails spam:clear_onboarding_jobs
#   bin/rails "spam:purge_signups[2026-11-10 00:00,2026-11-11 00:00]"              # dry run
#   CONFIRM=1 KEEP=real@x.com,other@y.com bin/rails "spam:purge_signups[2026-11-10,2026-11-11]"
#
# NOTE: these tasks only see jobs stored in Sidekiq (Redis). If ActiveJob uses
# the :async adapter, scheduled jobs live in the web process's memory instead
# and are dropped when that process restarts / redeploys.

module SpamCleanup
  ONBOARDING_JOB_CLASSES = %w[OnboardingNudgeJob OnboardingCheckinJob].freeze
  MAIL_DELIVERY_CLASS    = "ActionMailer::MailDeliveryJob".freeze
  UUID_PATTERN = /\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/

  module_function

  def warn_if_not_sidekiq
    adapter = ActiveJob::Base.queue_adapter_name
    return if adapter.to_s == "sidekiq"

    puts "NOTE: ActiveJob adapter is #{adapter.inspect}, not Sidekiq. Jobs enqueued by the web app are"
    puts "      NOT in Redis and won't be found here. With :async they are in-process and are cleared"
    puts "      by restarting the web service. (Onboarding jobs also skip soft-deleted users.)"
  end

  # The ActiveJob class wrapped inside a Sidekiq job record.
  def wrapped_class(job)
    job.item["wrapped"] || job.klass
  end

  def onboarding_job?(job)
    ONBOARDING_JOB_CLASSES.include?(wrapped_class(job))
  end

  def onboarding_mail?(job)
    wrapped_class(job) == MAIL_DELIVERY_CLASS && job.value.include?("OnboardingMailer")
  end

  def user_ids_in(job)
    job.value.scan(UUID_PATTERN)
  end

  # Yields every job in the scheduled set, retry set and all queues.
  def each_sidekiq_job(&block)
    require "sidekiq/api"
    Sidekiq::ScheduledSet.new.each(&block)
    Sidekiq::RetrySet.new.each(&block)
    Sidekiq::Queue.all.each { |queue| queue.each(&block) }
  end

  def parse_time!(value, name)
    Time.zone.parse(value.to_s) || raise(ArgumentError)
  rescue ArgumentError
    abort "Invalid #{name}: #{value.inspect} (expected e.g. 2026-11-10 or '2026-11-10 08:00')"
  end

  def suspects(since, until_time, keep_emails)
    other_members = CompanyMembership
      .where(deleted_at: nil)
      .where("company_memberships.user_id <> users.id")
      .where(
        "company_memberships.company_id IN (" \
        "SELECT own.company_id FROM company_memberships own " \
        "WHERE own.user_id = users.id AND own.deleted_at IS NULL)"
      )

    scope = User
      .where(deleted_at: nil, created_at: since...until_time)
      .where("users.sign_in_count <= 1")
      .where("NOT EXISTS (#{other_members.select('1').to_sql})")

    scope = scope.where.not("LOWER(users.email) IN (?)", keep_emails) if keep_emails.any?
    scope.order(:created_at)
  end
end

namespace :spam do
  desc "Emergency brake: delete every scheduled OnboardingNudgeJob / OnboardingCheckinJob from Sidekiq"
  task clear_onboarding_jobs: :environment do
    require "sidekiq/api"
    SpamCleanup.warn_if_not_sidekiq

    deleted = 0
    Sidekiq::ScheduledSet.new.each do |job|
      next unless SpamCleanup.onboarding_job?(job)

      job.delete
      deleted += 1
    end

    puts "Deleted #{deleted} scheduled onboarding job(s) from Sidekiq::ScheduledSet."
  end

  desc "Soft-delete bot sign-ups in [since, until). Dry run unless CONFIRM=1. KEEP=a@x.com,b@y.com to exclude."
  task :purge_signups, [:since, :until] => :environment do |_t, args|
    abort "Usage: bin/rails \"spam:purge_signups[SINCE,UNTIL]\"  (UNTIL defaults to now)" if args[:since].blank?

    since      = SpamCleanup.parse_time!(args[:since], "since")
    until_time = args[:until].present? ? SpamCleanup.parse_time!(args[:until], "until") : Time.current
    keep       = ENV.fetch("KEEP", "").split(",").map { |e| e.strip.downcase }.reject(&:blank?)
    apply      = ENV["CONFIRM"] == "1"

    scope = SpamCleanup.suspects(since, until_time, keep)
    count = scope.count

    puts "#{apply ? 'APPLYING' : 'DRY RUN'} — suspects created in [#{since}, #{until_time})"
    puts "Excluding (KEEP): #{keep.join(', ')}" if keep.any?
    puts "Suspect users: #{count}"
    puts
    scope.limit(50).pluck(:created_at, :email, :full_name).each do |created_at, email, full_name|
      puts format("  %-25s  %-45s  %s", created_at.utc.iso8601, email, full_name)
    end
    puts "  … and #{count - 50} more" if count > 50
    puts

    unless apply
      puts "Dry run only. Re-run with CONFIRM=1 to soft-delete these users and their companies."
      next
    end

    user_ids = scope.pluck(:id)
    id_set   = user_ids.to_set

    # 1. Remove their pending onboarding jobs and onboarding emails from Sidekiq.
    SpamCleanup.warn_if_not_sidekiq
    removed_jobs = 0
    begin
      SpamCleanup.each_sidekiq_job do |job|
        next unless SpamCleanup.onboarding_job?(job) || SpamCleanup.onboarding_mail?(job)
        next unless SpamCleanup.user_ids_in(job).any? { |id| id_set.include?(id) }

        job.delete
        removed_jobs += 1
      end
      puts "Removed #{removed_jobs} Sidekiq onboarding job(s)/email(s)."
    rescue StandardError => e
      puts "WARNING: could not clean Sidekiq jobs (#{e.class}: #{e.message}). Continuing with soft-delete."
    end

    # 2. Soft-delete users and their (sole-member) companies. No hard deletes.
    now = Time.current
    users_updated = companies_updated = 0
    user_ids.each_slice(500) do |batch|
      ActiveRecord::Base.transaction do
        company_ids = CompanyMembership.where(user_id: batch).distinct.pluck(:company_id)
        companies_updated += Company.where(id: company_ids, deleted_at: nil)
                                    .update_all(deleted_at: now, active: false, updated_at: now)
        users_updated += User.where(id: batch, deleted_at: nil)
                             .update_all(deleted_at: now, updated_at: now)
      end
    end

    puts "Soft-deleted #{users_updated} user(s) and #{companies_updated} compan(y/ies)."
  end
end
