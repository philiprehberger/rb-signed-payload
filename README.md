# philiprehberger-signed_payload

[![Tests](https://github.com/philiprehberger/rb-signed-payload/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-signed-payload/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-signed_payload.svg)](https://rubygems.org/gems/philiprehberger-signed_payload)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-signed-payload)](https://github.com/philiprehberger/rb-signed-payload/commits/main)

Cryptographic signing and verification for JSON payloads

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-signed_payload"
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

### Algorithm selection

```ruby
# Use SHA-512 instead of the default SHA-256
token = Philiprehberger::SignedPayload.sign(data, key: key, algorithm: :sha512)
result = Philiprehberger::SignedPayload.verify(token, key: key, algorithm: :sha512)

# Available algorithms: :sha256 (default), :sha384, :sha512
signer = Philiprehberger::SignedPayload::Signer.new(key: "my-secret", algorithm: :sha384)
```

### Quick validation

```ruby
# Check validity without raising exceptions
Philiprehberger::SignedPayload.valid?(token, key: key)
# => true or false

# Decode payload without verifying signature
Philiprehberger::SignedPayload.decode(token)
# => { "user_id" => 42, "role" => "admin" }

# Also available on Signer instances
signer = Philiprehberger::SignedPayload::Signer.new(key: "my-secret")
signer.valid?(token)   # => true or false
signer.decode(token)   # => { "user_id" => 42, "role" => "admin" }
```

### Token Refresh

```ruby
# Re-sign a verified token with a new expiration
refreshed = Philiprehberger::SignedPayload.refresh(token, key: key, expires_in: 7200)
```

### Token Inspection

```ruby
# Check if a token has expired (without verifying signature)
Philiprehberger::SignedPayload.expired?(token)  # => true or false

# Inspect token metadata without verification
info = Philiprehberger::SignedPayload.peek(token)
info[:data]     # => { "user_id" => 42 }
info[:exp]      # => 1712700000 (Unix timestamp, or nil)
info[:expired]  # => false
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
| `SignedPayload.sign(data, key:, expires_in:, algorithm:)` | Sign data, returns token string |
| `SignedPayload.verify(token, key:, algorithm:)` | Verify and decode token, returns data hash |
| `SignedPayload.valid?(token, key:)` | Check signature validity, returns boolean |
| `SignedPayload.decode(token)` | Decode payload without verification |
| `SignedPayload.refresh(token, key:, expires_in:)` | Re-sign a token with new expiration |
| `SignedPayload.expired?(token)` | Check if token has expired |
| `SignedPayload.peek(token)` | Inspect token metadata without verification |
| `Signer.new(key:, algorithm:)` | Create a signer instance |
| `Signer#sign(data, expires_in:)` | Sign data with optional TTL |
| `Signer#verify(token)` | Verify token or raise error |
| `Signer#valid?(token)` | Check signature validity, returns boolean |
| `Signer#decode(token)` | Decode payload without verification |
| `Signer#refresh(token, expires_in:)` | Re-sign a verified token with new TTL |
| `Signer#expired?(token)` | Check if token has expired |
| `Signer#peek(token)` | Inspect data, exp, and expired status |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-signed-payload)

🐛 [Report issues](https://github.com/philiprehberger/rb-signed-payload/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-signed-payload/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
