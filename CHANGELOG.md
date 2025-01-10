# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-09

### Added
- `refresh(token, expires_in:)` to re-sign a verified token with a new expiration
- `expired?(token)` to check token expiration without verifying the signature
- `peek(token)` to inspect token metadata (data, exp, expired) without verification

### Fixed
- Deduplicate version `0.2.3` entries in CHANGELOG

## [0.2.8] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.2.7] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.6] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

## [0.2.5] - 2026-03-24

### Fixed
- Fix README one-liner to remove trailing period and match gemspec summary

## [0.2.4] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.2.3] - 2026-03-22

### Changed
- Expand test coverage to 30+ examples with empty/nil/large payloads, tamper detection, key sensitivity, unsupported algorithm, and decode edge cases

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
