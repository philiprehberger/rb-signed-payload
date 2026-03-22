# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.4] - 2026-03-22

### Changed

- Expand test coverage to 30+ examples with empty/nil/large payloads, tamper detection, key sensitivity, unsupported algorithm, and decode edge cases

## [0.2.3] - 2026-03-21

### Fixed
- Standardize Installation section in README

## [0.2.2] - 2026-03-18

### Fixed
- Fix RuboCop Style/StringLiterals violations in gemspec

## [0.2.1] - 2026-03-16

### Added
- Add License badge to README
- Add bug_tracker_uri to gemspec

## [0.2.0] - 2026-03-12

### Added
- Support for multiple HMAC algorithms: `:sha256` (default), `:sha384`, `:sha512`
- `algorithm:` parameter on `sign`, `verify`, and `Signer.new`
- `valid?` method for boolean signature checking without exceptions
- `decode` method for reading payload without signature verification

## [0.1.0] - 2026-03-10

### Added
- Initial release
- HMAC-SHA256 signing and verification for JSON payloads
- Base64-encoded token format (`base64(payload).base64(signature)`)
- Optional token expiration with TTL support
- Timing-safe signature comparison
- Module-level convenience methods (`sign` and `verify`)
