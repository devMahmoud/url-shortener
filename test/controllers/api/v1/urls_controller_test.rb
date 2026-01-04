require "test_helper"

class Api::V1::UrlsControllerTest < ActionDispatch::IntegrationTest
  # Encode endpoint tests
  test "api encode creates shortened URL" do
    post api_v1_encode_url, params: { url: "https://api-test.com/long/path" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json["short_url"].present?
    assert json["short_code"].present?
    assert_equal "https://api-test.com/long/path", json["original_url"]
    assert_equal 6, json["short_code"].length
  end

  test "api encode returns same short URL for duplicate original URL" do
    original_url = "https://api-duplicate-test.com/path"

    post api_v1_encode_url, params: { url: original_url }, as: :json
    first_response = JSON.parse(response.body)

    post api_v1_encode_url, params: { url: original_url }, as: :json
    second_response = JSON.parse(response.body)

    assert_equal first_response["short_code"], second_response["short_code"]
  end

  test "api encode rejects invalid URL" do
    post api_v1_encode_url, params: { url: "not-a-valid-url" }, as: :json
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert json["errors"].present?
  end

  test "api encode rejects empty URL" do
    post api_v1_encode_url, params: { url: "" }, as: :json
    assert_response :unprocessable_entity
  end

  test "api encode does not require CSRF token" do
    post api_v1_encode_url, params: { url: "https://no-csrf.com" }, as: :json
    assert_response :success
  end

  # Decode endpoint tests
  test "api decode returns original URL for valid short code" do
    existing = urls(:google)
    get api_v1_decode_url, params: { short_code: existing.short_code }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal existing.original_url, json["original_url"]
  end

  test "api decode accepts full short URL" do
    existing = urls(:google)
    short_url = "http://example.com/#{existing.short_code}"
    get api_v1_decode_url, params: { short_url: short_url }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal existing.original_url, json["original_url"]
  end

  test "api decode returns 404 for non-existent short code" do
    get api_v1_decode_url, params: { short_code: "zzzzzz" }
    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "URL not found", json["error"]
  end

  # Round-trip test
  test "api encoded URLs can be decoded" do
    original = "https://api-roundtrip.com/test"

    # Encode
    post api_v1_encode_url, params: { url: original }, as: :json
    encode_response = JSON.parse(response.body)
    short_code = encode_response["short_code"]

    # Decode
    get api_v1_decode_url, params: { short_code: short_code }
    decode_response = JSON.parse(response.body)

    assert_equal original, decode_response["original_url"]
  end
end
