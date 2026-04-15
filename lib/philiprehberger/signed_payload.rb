# frozen_string_literal: true

require 'json'
require 'base64'

require_relative 'signed_payload/version'
require_relative 'signed_payload/errors'
require_relative 'signed_payload/signer'

module Philiprehberger
  module SignedPayload
    def self.sign(data, key:, algorithm: :sha256, expires_in: nil)
      Signer.new(key: key, algorithm: algorithm).sign(data, expires_in: expires_in)
    end

    def self.verify(token, key:, algorithm: :sha256)
      Signer.new(key: key, algorithm: algorithm).verify(token)
    end

    def self.valid?(token, key:, algorithm: :sha256)
      Signer.new(key: key, algorithm: algorithm).valid?(token)
    end

    def self.refresh(token, key:, expires_in:, algorithm: :sha256)
      Signer.new(key: key, algorithm: algorithm).refresh(token, expires_in: expires_in)
    end

    def self.rotate(token, old_key:, new_key:, algorithm: :sha256)
      old_signer = Signer.new(key: old_key, algorithm: algorithm)
      data = old_signer.verify(token)
      exp = old_signer.peek(token)[:exp]
      Signer.new(key: new_key, algorithm: algorithm).sign_with_exp(data, exp: exp)
    end

    def self.expired?(token)
      Signer.new(key: 'unused').expired?(token)
    end

    def self.peek(token)
      Signer.new(key: 'unused').peek(token)
    end

    def self.decode(token)
      encoded, _sig = token.to_s.split('.')
      raise MalformedToken, 'invalid token format' unless token.to_s.split('.').length == 2

      parsed = JSON.parse(Base64.urlsafe_decode64(encoded))
      parsed['data']
    rescue JSON::ParserError
      raise MalformedToken, 'invalid payload encoding'
    end
  end
end
