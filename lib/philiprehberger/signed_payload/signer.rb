# frozen_string_literal: true

require 'openssl'
require 'json'
require 'base64'

module Philiprehberger
  module SignedPayload
    class Signer
      ALGORITHMS = {
        sha256: 'SHA256',
        sha384: 'SHA384',
        sha512: 'SHA512'
      }.freeze

      def initialize(key:, algorithm: :sha256)
        @key = key
        @algorithm = validate_algorithm!(algorithm)
      end

      def sign(data, expires_in: nil)
        payload = build_payload(data, expires_in)
        encoded = Base64.urlsafe_encode64(payload)
        signature = compute_signature(encoded)
        "#{encoded}.#{Base64.urlsafe_encode64(signature)}"
      end

      def verify(token)
        encoded, sig = split_token(token)
        verify_signature!(encoded, sig)
        decode_payload(encoded)
      end

      def valid?(token)
        verify(token)
        true
      rescue Error
        false
      end

      def decode(token)
        encoded, _sig = split_token(token)
        parsed = JSON.parse(Base64.urlsafe_decode64(encoded))
        parsed['data']
      rescue JSON::ParserError
        raise MalformedToken, 'invalid payload encoding'
      end

      private

      def build_payload(data, expires_in)
        hash = { 'data' => data }
        hash['exp'] = Time.now.to_i + expires_in if expires_in
        JSON.generate(hash)
      end

      def split_token(token)
        parts = token.to_s.split('.')
        raise MalformedToken, 'invalid token format' unless parts.length == 2

        parts
      end

      def verify_signature!(encoded, sig)
        expected = compute_signature(encoded)
        actual = Base64.urlsafe_decode64(sig)
        raise InvalidSignature, 'signature mismatch' unless secure_compare(expected, actual)
      rescue ArgumentError
        raise InvalidSignature, 'signature mismatch'
      end

      def decode_payload(encoded)
        parsed = JSON.parse(Base64.urlsafe_decode64(encoded))
        check_expiration!(parsed)
        parsed['data']
      rescue JSON::ParserError
        raise MalformedToken, 'invalid payload encoding'
      end

      def check_expiration!(parsed)
        return unless parsed.key?('exp')

        raise ExpiredToken, 'token has expired' if parsed['exp'] <= Time.now.to_i
      end

      def validate_algorithm!(algorithm)
        digest = ALGORITHMS[algorithm]
        raise ArgumentError, "unsupported algorithm: #{algorithm}" unless digest

        digest
      end

      def compute_signature(payload)
        OpenSSL::HMAC.digest(@algorithm, @key, payload)
      end

      def secure_compare(val_a, val_b)
        OpenSSL.fixed_length_secure_compare(val_a, val_b)
      rescue ArgumentError
        false
      end
    end
  end
end
