# frozen_string_literal: true

# Service object for URL shortening operations.
# Provides a clean interface for both web and API controllers.
class UrlService
  # Result object for service operations
  class Result
    attr_reader :url, :error

    def initialize(success:, url: nil, error: nil)
      @success = success
      @url = url
      @error = error
    end

    def success?
      @success
    end
  end

  class << self
    # Encode a long URL to a short URL
    # @param original_url [String] the URL to shorten
    # @return [Result] with success status, url object, and optional error
    def encode(original_url)
      url = Url.encode(original_url)

      if url.persisted?
        Result.new(success: true, url: url)
      else
        Result.new(success: false, error: url.errors.full_messages)
      end
    end

    # Decode a short URL/code to retrieve the original URL
    # @param short_url_or_code [String] the short URL or just the code
    # @return [Result] with success status, url object, and optional error
    def decode(short_url_or_code)
      short_code = extract_short_code(short_url_or_code)
      url = Url.decode(short_code)

      if url
        Result.new(success: true, url: url)
      else
        Result.new(success: false, error: "URL not found")
      end
    end

    private

    # Extract short code from full URL or return as-is if already a code
    def extract_short_code(input)
      return nil if input.blank?

      if input.include?("/")
        URI.parse(input).path.split("/").last
      else
        input
      end
    rescue URI::InvalidURIError
      input
    end
  end
end
