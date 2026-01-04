class UrlsController < ApplicationController
  # POST /encode
  # Accepts: { url: "https://example.com/long/path" }
  # Returns: { short_url: "http://your.domain/abc123", short_code: "abc123" }
  def encode
    result = UrlService.encode(params[:url])

    if result.success?
      render json: {
        short_url: short_url_for(result.url.short_code),
        short_code: result.url.short_code,
        original_url: result.url.original_url
      }, status: :ok
    else
      render json: { errors: result.error }, status: :unprocessable_entity
    end
  end

  # GET /decode
  # Accepts: { short_url: "http://your.domain/abc123" } or { short_code: "abc123" }
  # Returns: { original_url: "https://example.com/long/path" }
  def decode
    input = params[:short_url] || params[:short_code]
    result = UrlService.decode(input)

    if result.success?
      render json: {
        original_url: result.url.original_url,
        short_url: short_url_for(result.url.short_code),
        short_code: result.url.short_code
      }, status: :ok
    else
      render json: { error: result.error }, status: :not_found
    end
  end

  # GET /
  # Renders the home page with encode/decode form
  def home
  end

  # GET /:short_code
  # Redirects to the original URL
  def redirect
    result = UrlService.decode(params[:short_code])

    if result.success?
      redirect_to result.url.original_url, allow_other_host: true, status: :moved_permanently
    else
      render plain: "URL not found", status: :not_found
    end
  end

  private

  def short_url_for(short_code)
    "#{request.base_url}/#{short_code}"
  end
end
