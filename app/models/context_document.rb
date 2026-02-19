class ContextDocument < ApplicationRecord
  INGESTION_STATUSES = %w[pending ingested failed].freeze
  TEXT_FORMATS = %w[plain csv ocr].freeze

  belongs_to :user

  validates :filename, presence: true
  validates :content_type, presence: true
  validates :byte_size, numericality: { greater_than_or_equal_to: 0 }
  validates :source_checksum, presence: true
  validates :ingestion_status, inclusion: { in: INGESTION_STATUSES }
  validates :text_format, inclusion: { in: TEXT_FORMATS }
end
