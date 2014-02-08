# frozen_string_literal: true

require_relative "lib/philiprehberger/signed_payload/version"

Gem::Specification.new do |spec|
  spec.name = "philiprehberger-signed_payload"
  spec.version = Philiprehberger::SignedPayload::VERSION
  spec.authors = ["Philip Rehberger"]
  spec.email = ["me@philiprehberger.com"]

  spec.summary = "Cryptographic signing and verification for JSON payloads"
  spec.description = "A zero-dependency Ruby gem for signing and verifying JSON payloads " \
                     "using HMAC-SHA256 with optional expiration and timing-safe comparison."
  spec.homepage = "https://github.com/philiprehberger/rb-signed-payload"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.require_paths = ["lib"]
end
