class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  CHANNELS = %w[email in_app].freeze
  EVENTS   = %w[
    savings_plan_submitted
    savings_plan_approved
    savings_plan_declined
    monthly_savings_confirmed
    withdrawal_requested
    withdrawal_approved
    withdrawal_declined
    advance_submitted
    advance_approved
    advance_declined
    advance_disbursed
    advance_repayment_deducted
    advance_settled
  ].freeze

  enum :channel, { email: "email", in_app: "in_app" }

  validates :channel, inclusion: { in: CHANNELS }
  validates :event,   inclusion: { in: EVENTS }

  scope :unread, -> { where(read: false) }
  scope :sent,   -> { where(sent: true) }

  def mark_read!
    update!(read: true, read_at: Time.current) unless read?
  end
end
