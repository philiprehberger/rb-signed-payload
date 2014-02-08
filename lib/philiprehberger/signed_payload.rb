# frozen_string_literal: true

require_relative "signed_payload/version"
require_relative "signed_payload/errors"
require_relative "signed_payload/signer"

module Philiprehberger
  module SignedPayload
    def self.sign(data, key:, expires_in: nil)
      Signer.new(key: key).sign(data, expires_in: expires_in)
    end

    def self.verify(token, key:)
      Signer.new(key: key).verify(token)
    end
  end
end
