class Url < ApplicationRecord
  SHORT_CODE_LENGTH = 6
  MAX_COLLISION_RETRIES = 10

  validates :original_url, presence: true, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    message: "must be a valid HTTP or HTTPS URL"
  }
  validates :short_code, presence: true, uniqueness: true

  before_validation :generate_short_code, on: :create

  # Find existing URL or create new one for the given original_url
  def self.encode(original_url)
    find_by(original_url: original_url) || create(original_url: original_url)
  end

  # Find original URL by short code
  def self.decode(short_code)
    find_by(short_code: short_code)
  end

  private

  def generate_short_code
    return if short_code.present?

    retries = 0
    loop do
      self.short_code = SecureRandom.alphanumeric(SHORT_CODE_LENGTH)
      break unless Url.exists?(short_code: short_code)

      retries += 1
      raise "Could not generate unique short code after #{MAX_COLLISION_RETRIES} attempts" if retries >= MAX_COLLISION_RETRIES
    end
  end
end
