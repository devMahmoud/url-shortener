require "test_helper"

class UrlTest < ActiveSupport::TestCase
  test "validates presence of original_url" do
    url = Url.new(original_url: nil)
    assert_not url.valid?
    assert_includes url.errors[:original_url], "can't be blank"
  end

  test "validates URL format" do
    url = Url.new(original_url: "not-a-valid-url")
    assert_not url.valid?
    assert_includes url.errors[:original_url], "must be a valid HTTP or HTTPS URL"
  end

  test "accepts valid HTTP URL" do
    url = Url.new(original_url: "http://example.com")
    assert url.valid?
  end

  test "accepts valid HTTPS URL" do
    url = Url.new(original_url: "https://example.com/path?query=1")
    assert url.valid?
  end

  test "rejects FTP URL" do
    url = Url.new(original_url: "ftp://example.com/file")
    assert_not url.valid?
  end

  test "generates short code on create" do
    url = Url.create!(original_url: "https://example.com/new-page")
    assert_not_nil url.short_code
    assert_equal 6, url.short_code.length
    assert_match(/\A[a-zA-Z0-9]+\z/, url.short_code)
  end

  test "does not regenerate short code on update" do
    url = Url.create!(original_url: "https://example.com")
    original_code = url.short_code
    url.update!(original_url: "https://example.org")
    assert_equal original_code, url.short_code
  end

  test "encode returns existing URL for same original_url" do
    existing = urls(:google)
    result = Url.encode(existing.original_url)
    assert_equal existing.id, result.id
    assert_equal existing.short_code, result.short_code
  end

  test "encode creates new URL for new original_url" do
    original = "https://newsite.com/unique-path"
    assert_difference "Url.count", 1 do
      result = Url.encode(original)
      assert result.persisted?
      assert_equal original, result.original_url
    end
  end

  test "decode finds URL by short code" do
    existing = urls(:google)
    result = Url.decode(existing.short_code)
    assert_equal existing.id, result.id
  end

  test "decode returns nil for non-existent short code" do
    result = Url.decode("zzzzzz")
    assert_nil result
  end

  test "short code uniqueness" do
    existing = urls(:google)
    new_url = Url.new(original_url: "https://different.com", short_code: existing.short_code)
    assert_not new_url.valid?
    assert_includes new_url.errors[:short_code], "has already been taken"
  end
end
