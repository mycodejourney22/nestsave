class Rota < ApplicationRecord
  self.table_name = "rotas"

  belongs_to :team
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  has_many :rota_entries, dependent: :destroy

  enum :status, { draft: "draft", published: "published" }

  validates :week_start, :week_end, presence: true
  validates :week_start,
            uniqueness: { scope: :team_id, message: "rota already exists for this week" }
  validate  :week_end_after_week_start

  before_validation :set_week_end,
                    if: -> { week_start.present? && week_end.blank? }

  scope :published, -> { where(status: :published) }
  scope :upcoming,  -> { where("week_start >= ?", Date.current) }
  scope :recent,    -> { order(week_start: :desc) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def week_label
    "#{week_start.strftime("%-d %b")} – #{week_end.strftime("%-d %b %Y")}"
  end

  private

  def set_week_end
    self.week_end = week_start + 6.days
  end

  def week_end_after_week_start
    return unless week_start && week_end
    errors.add(:week_end, "must be after week start") if week_end < week_start
  end
end
