# philiprehberger-signed_payload

[![Tests](https://github.com/philiprehberger/rb-signed-payload/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-signed-payload/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-signed_payload.svg)](https://rubygems.org/gems/philiprehberger-signed_payload)

Simple cryptographic signing and verification for JSON payloads using HMAC-SHA256.

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-signed_payload"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install philiprehberger-signed_payload
```

## Usage

### Sign and verify data

```ruby
require "philiprehberger/signed_payload"

key = "my-secret-key"
data = { "user_id" => 42, "role" => "admin" }

# Sign data into a token
token = Philiprehberger::SignedPayload.sign(data, key: key)
# => "eyJkYXRhIjp7InVzZXJfaWQiOjQyLCJyb2xlIjoiYWRtaW4ifX0=.HMAC_SIG..."

# Verify and decode
result = Philiprehberger::SignedPayload.verify(token, key: key)
# => { "user_id" => 42, "role" => "admin" }
```

### With expiration

```ruby
# Token expires in 1 hour
token = Philiprehberger::SignedPayload.sign(data, key: key, expires_in: 3600)

# Raises Philiprehberger::SignedPayload::ExpiredToken after 1 hour
Philiprehberger::SignedPayload.verify(token, key: key)
```

### Using the Signer class directly

```ruby
signer = Philiprehberger::SignedPayload::Signer.new(key: "my-secret")

token = signer.sign({ "action" => "approve" }, expires_in: 300)
data = signer.verify(token)
# => { "action" => "approve" }
```

### Error handling

```ruby
begin
  Philiprehberger::SignedPayload.verify(token, key: key)
rescue Philiprehberger::SignedPayload::InvalidSignature
  # Signature does not match (tampered or wrong key)
rescue Philiprehberger::SignedPayload::ExpiredToken
  # Token TTL has elapsed
rescue Philiprehberger::SignedPayload::MalformedToken
  # Token format is invalid
end
```

## API

| Method | Description |
|--------|-------------|
| `SignedPayload.sign(data, key:, expires_in:)` | Sign data, returns token string |
| `SignedPayload.verify(token, key:)` | Verify and decode token, returns data hash |
| `Signer.new(key:)` | Create a signer instance |
| `Signer#sign(data, expires_in:)` | Sign data with optional TTL |
| `Signer#verify(token)` | Verify token or raise error |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## License

MIT
