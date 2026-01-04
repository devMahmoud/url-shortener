# frozen_string_literal: true

module Api
  module V1
    # API controller for URL shortening operations.
    # Provides JSON endpoints for encoding and decoding URLs.
    class UrlsController < Api::BaseController
      # POST /api/v1/encode
      # Encodes a URL to a shortened URL.
      #
      # Request body:
      #   { "url": "https://example.com/long/path" }
      #
      # Success response (200):
      #   { "short_url": "http://domain/abc123", "short_code": "abc123", "original_url": "..." }
      #
      # Error response (422):
      #   { "errors": ["Original url must be a valid HTTP or HTTPS URL"] }
      def encode
        result = UrlService.encode(params[:url])

        if result.success?
          render_success({
            short_url: short_url_for(result.url.short_code),
            short_code: result.url.short_code,
            original_url: result.url.original_url
          })
        else
          render_errors(result.error, status: :unprocessable_entity)
        end
      end

      # GET /api/v1/decode
      # Decodes a shortened URL to its original URL.
      #
      # Query params:
      #   short_url: "http://domain/abc123" OR short_code: "abc123"
      #
      # Success response (200):
      #   { "original_url": "https://example.com", "short_url": "...", "short_code": "abc123" }
      #
      # Error response (404):
      #   { "error": "URL not found" }
      def decode
        input = params[:short_url] || params[:short_code]
        result = UrlService.decode(input)

        if result.success?
          render_success({
            original_url: result.url.original_url,
            short_url: short_url_for(result.url.short_code),
            short_code: result.url.short_code
          })
        else
          render_error(result.error, status: :not_found)
        end
      end

      private

      def short_url_for(short_code)
        "#{request.base_url}/#{short_code}"
      end
    end
  end
end
