require "test_helper"

class UrlServiceTest < ActiveSupport::TestCase
  test "encode returns success for valid URL" do
    result = UrlService.encode("https://service-test.com/path")
    assert result.success?
    assert result.url.persisted?
    assert_equal "https://service-test.com/path", result.url.original_url
  end

  test "encode returns existing URL for duplicate" do
    existing = urls(:google)
    result = UrlService.encode(existing.original_url)
    assert result.success?
    assert_equal existing.id, result.url.id
  end

  test "encode returns failure for invalid URL" do
    result = UrlService.encode("not-valid")
    assert_not result.success?
    assert result.error.present?
  end

  test "encode returns failure for empty URL" do
    result = UrlService.encode("")
    assert_not result.success?
  end

  test "decode returns success for valid short code" do
    existing = urls(:google)
    result = UrlService.decode(existing.short_code)
    assert result.success?
    assert_equal existing.original_url, result.url.original_url
  end

  test "decode extracts short code from full URL" do
    existing = urls(:google)
    result = UrlService.decode("http://example.com/#{existing.short_code}")
    assert result.success?
    assert_equal existing.id, result.url.id
  end

  test "decode returns failure for non-existent code" do
    result = UrlService.decode("zzzzzz")
    assert_not result.success?
    assert_equal "URL not found", result.error
  end

  test "decode handles nil input" do
    result = UrlService.decode(nil)
    assert_not result.success?
  end

  test "decode handles empty input" do
    result = UrlService.decode("")
    assert_not result.success?
  end
end
