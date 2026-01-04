# ShortLink - URL Shortener

A Ruby on Rails URL shortening service with a simple web interface and JSON API.

## Features

- **Encode URLs**: Convert long URLs to short, shareable links
- **Decode URLs**: Retrieve original URLs from short codes
- **Redirect**: Short URLs automatically redirect to original destinations
- **Persistence**: URLs persist across server restarts (PostgreSQL)
- **Idempotent**: Same original URL always returns same short code

## Requirements

- Ruby 3.1+
- PostgreSQL 9.3+
- Bundler

## Setup

```bash
# Install dependencies
bundle install

# Create and migrate databases
rails db:create db:migrate

# Start the server
rails server
```

The application will be available at `http://localhost:3000`

## Running Tests

```bash
# Run all tests (41 tests)
rails test

# Run specific test files
rails test test/models/url_test.rb           # Model tests
rails test test/controllers/urls_controller_test.rb  # Web controller tests
rails test test/controllers/api/             # API controller tests
rails test test/services/                    # Service tests
```

## API Endpoints

This application provides two sets of endpoints:
- **Web endpoints** (`/encode`, `/decode`) - Used by the frontend, require CSRF tokens
- **API endpoints** (`/api/v1/encode`, `/api/v1/decode`) - For external integrations, no CSRF required

### POST /api/v1/encode

Shorten a URL (API endpoint, no CSRF token required).

**Request:**
```bash
curl -X POST http://localhost:3000/api/v1/encode \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/very/long/path"}'
```

**Response (200 OK):**
```json
{
  "short_url": "http://localhost:3000/abc123",
  "short_code": "abc123",
  "original_url": "https://example.com/very/long/path"
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "errors": ["Original url must be a valid HTTP or HTTPS URL"]
}
```

### GET /api/v1/decode

Retrieve the original URL (API endpoint).

**Request:**
```bash
curl "http://localhost:3000/api/v1/decode?short_code=abc123"
# or
curl "http://localhost:3000/api/v1/decode?short_url=http://localhost:3000/abc123"
```

**Response (200 OK):**
```json
{
  "original_url": "https://example.com/very/long/path",
  "short_url": "http://localhost:3000/abc123",
  "short_code": "abc123"
}
```

**Error Response (404 Not Found):**
```json
{
  "error": "URL not found"
}
```

### GET /:short_code

Redirects to the original URL with HTTP 301 (Moved Permanently).

## Security Considerations

### Implemented Protections

1. **URL Validation**: Only HTTP/HTTPS URLs are accepted. FTP, file://, javascript:, and other protocols are rejected.

2. **CSRF Protection**: Rails' built-in CSRF tokens protect form submissions.

3. **SQL Injection Prevention**: ActiveRecord parameterized queries prevent SQL injection.

4. **XSS Prevention**: Rails' default HTML escaping in views.

### Potential Attack Vectors & Mitigations

| Attack Vector | Risk | Mitigation Strategy |
|--------------|------|---------------------|
| **Malicious URL Distribution** | High | Consider integrating URL reputation services (Google Safe Browsing API) to check URLs before shortening |
| **Brute Force Enumeration** | Medium | Short codes use 62-character alphabet (a-z, A-Z, 0-9) with 6 characters = 56B+ combinations. Add rate limiting for decode endpoint |
| **Open Redirect Abuse** | Medium | Log all redirects with IP/timestamp for abuse tracking. Consider adding interstitial warning pages |
| **Denial of Service** | Medium | Implement rate limiting on /encode endpoint (e.g., rack-attack gem) |
| **Phishing via Similar Domains** | Low | Consider URL preview before redirect |

### Recommended Production Hardening

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  throttle('encode/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path == '/encode' && req.post?
  end
end
```

## Scalability Considerations

### Current Implementation

- **Short Code Generation**: 6-character alphanumeric codes using `SecureRandom.alphanumeric`
- **Collision Handling**: Retry loop with 10 max attempts
- **Database**: PostgreSQL with unique index on `short_code`, index on `original_url`

### Capacity Analysis

| Code Length | Possible Combinations | Collision Probability at 1M URLs |
|-------------|----------------------|----------------------------------|
| 6 chars     | 56.8 billion         | ~0.0018%                        |
| 7 chars     | 3.5 trillion         | ~0.00003%                       |
| 8 chars     | 218 trillion         | negligible                       |

### Scaling Strategies

1. **Increase Code Length**: Change `SHORT_CODE_LENGTH` in `app/models/url.rb` from 6 to 7-8 for more headroom.

2. **Pre-generated Code Pool**: Generate short codes in batches and store in a separate table, pop from pool on demand.

3. **Database Scaling**:
   - Add read replicas for decode/redirect operations
   - Consider Redis cache for hot URLs
   - Partition urls table by created_at for archival

4. **Horizontal Scaling**:
   - Application is stateless, easily scaled behind load balancer
   - Use distributed ID generation (Snowflake-style) if multi-region

### Alternative Approaches for High Scale

```ruby
# Base62 encoding of auto-increment ID (deterministic, no collisions)
def generate_short_code
  # After save, encode the ID
  self.short_code = id.to_s(36).rjust(6, '0')
end
```

## Project Structure

```
app/
├── controllers/
│   ├── urls_controller.rb           # Web endpoints (encode, decode, redirect, home)
│   └── api/
│       ├── base_controller.rb       # API base with error handling, no CSRF
│       └── v1/
│           └── urls_controller.rb   # API v1 endpoints
├── models/
│   └── url.rb                       # URL model with validation & code generation
├── services/
│   └── url_service.rb               # Business logic shared by all controllers
└── views/
    └── urls/
        └── home.html.erb            # Frontend UI

test/
├── controllers/
│   ├── urls_controller_test.rb      # Web controller tests
│   └── api/v1/
│       └── urls_controller_test.rb  # API controller tests
├── models/
│   └── url_test.rb                  # Unit tests for Url model
├── services/
│   └── url_service_test.rb          # Service tests
└── fixtures/
    └── urls.yml                     # Test data
```

## Architecture

The application follows a layered architecture:

1. **Controllers** handle HTTP requests/responses
   - `UrlsController` - Web endpoints with CSRF protection
   - `Api::V1::UrlsController` - API endpoints without CSRF
2. **Services** contain business logic
   - `UrlService` - Encoding/decoding logic shared across controllers
3. **Models** handle data persistence and validation
   - `Url` - ActiveRecord model with URL validation and short code generation

## License

MIT
