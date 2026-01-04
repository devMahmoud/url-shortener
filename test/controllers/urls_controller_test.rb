require "test_helper"

class UrlsControllerTest < ActionDispatch::IntegrationTest
  # Home page tests
  test "home page loads successfully" do
    get root_url
    assert_response :success
  end

  # Encode endpoint tests
  test "encode creates shortened URL" do
    post encode_url, params: { url: "https://example.com/long/path" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json["short_url"].present?
    assert json["short_code"].present?
    assert_equal "https://example.com/long/path", json["original_url"]
    assert_equal 6, json["short_code"].length
  end

  test "encode returns same short URL for duplicate original URL" do
    original_url = "https://example.com/duplicate-test"

    post encode_url, params: { url: original_url }, as: :json
    first_response = JSON.parse(response.body)

    post encode_url, params: { url: original_url }, as: :json
    second_response = JSON.parse(response.body)

    assert_equal first_response["short_code"], second_response["short_code"]
  end

  test "encode rejects invalid URL" do
    post encode_url, params: { url: "not-a-valid-url" }, as: :json
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert json["errors"].present?
  end

  test "encode rejects empty URL" do
    post encode_url, params: { url: "" }, as: :json
    assert_response :unprocessable_entity
  end

  # Decode endpoint tests
  test "decode returns original URL for valid short code" do
    existing = urls(:google)
    get decode_url, params: { short_code: existing.short_code }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal existing.original_url, json["original_url"]
  end

  test "decode accepts full short URL" do
    existing = urls(:google)
    short_url = "http://example.com/#{existing.short_code}"
    get decode_url, params: { short_url: short_url }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal existing.original_url, json["original_url"]
  end

  test "decode returns 404 for non-existent short code" do
    get decode_url, params: { short_code: "zzzzzz" }
    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "URL not found", json["error"]
  end

  # Redirect endpoint tests
  test "redirect forwards to original URL" do
    existing = urls(:google)
    get short_url_url(short_code: existing.short_code)
    assert_response :moved_permanently
    assert_redirected_to existing.original_url
  end

  test "redirect returns 404 for non-existent short code" do
    get short_url_url(short_code: "zzzzzz")
    assert_response :not_found
  end

  # Persistence tests
  test "encoded URLs persist and can be decoded" do
    original = "https://persistence-test.com/path"

    # Encode
    post encode_url, params: { url: original }, as: :json
    encode_response = JSON.parse(response.body)
    short_code = encode_response["short_code"]

    # Decode should work
    get decode_url, params: { short_code: short_code }
    decode_response = JSON.parse(response.body)

    assert_equal original, decode_response["original_url"]
  end
end
