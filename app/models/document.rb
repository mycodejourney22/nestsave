class Document < ApplicationRecord
  belongs_to :employee_profile
  belongs_to :uploader, class_name: "User", foreign_key: :uploaded_by

  has_one_attached :file

  CATEGORIES = %w[contract right_to_work correspondence agreement other].freeze

  enum :category, {
    contract:       "contract",
    right_to_work:  "right_to_work",
    correspondence: "correspondence",
    agreement:      "agreement",
    other:          "other"
  }

  validates :title,    presence: true
  validates :category, presence: true
  validates :file,     presence: true

  scope :kept,    -> { where(deleted_at: nil) }
  scope :trashed, -> { where.not(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def deleted?
    deleted_at.present?
  end

  def category_label
    category.humanize.gsub("_", " ")
  end

  def file_url
    return nil unless file.attached?
    blob = file.blob
    public_id = "#{Rails.env}/#{blob.key}.#{blob.filename.extension}"
    Cloudinary::Utils.cloudinary_url(public_id, resource_type: "image", secure: true)
  end

  def download_url
    return nil unless file.attached?
    blob = file.blob
    public_id = "#{Rails.env}/#{blob.key}.#{blob.filename.extension}"
    Cloudinary::Utils.cloudinary_url(public_id, resource_type: "image", secure: true, flags: "attachment")
  end

  def file_size_display
    return nil unless file.attached?
    size = file.blob.byte_size
    size > 1.megabyte ?
      "#{"%.1f" % (size / 1.megabyte.to_f)} MB" :
      "#{(size / 1.kilobyte).round} KB"
  end
end
