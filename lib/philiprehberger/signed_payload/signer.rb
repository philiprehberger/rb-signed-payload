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

      # Verify a token's signature and decode its payload.
      #
      # @param token [String] the token to verify
      # @param keys [Array<String>, nil] optional list of candidate keys to try
      #   for zero-downtime secret rotation. Signature passes if any key
      #   validates. When nil (default), the key supplied at construction is
      #   used.
      # @return [Object] the decoded payload data
      # @raise [ArgumentError] if keys is an empty array
      # @raise [InvalidSignature, ExpiredToken, MalformedToken] on failure
      def verify(token, keys: nil)
        raise ArgumentError, 'no keys provided' if keys.is_a?(Array) && keys.empty?

        encoded, sig = split_token(token)
        verify_signature!(encoded, sig, keys: keys)
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

      # Re-sign a verified token with a new expiration.
      #
      # @param token [String] the token to refresh
      # @param expires_in [Integer] new TTL in seconds
      # @return [String] a new token with the same data and a fresh expiration
      # @raise [InvalidSignature, ExpiredToken, MalformedToken] if the current token is invalid
      def refresh(token, expires_in:)
        data = verify(token)
        sign(data, expires_in: expires_in)
      end

      # Re-sign a verified token's payload preserving the original expiration timestamp.
      # Used internally by key rotation to avoid shifting expiry during re-signing.
      #
      # @param data [Object] the payload data to sign
      # @param exp [Integer, nil] Unix timestamp to preserve (or nil for no expiry)
      # @return [String] a new token with the given data and exp
      def sign_with_exp(data, exp:)
        hash = { 'data' => data }
        hash['exp'] = exp unless exp.nil?
        payload = JSON.generate(hash)
        encoded = Base64.urlsafe_encode64(payload)
        signature = compute_signature(encoded)
        "#{encoded}.#{Base64.urlsafe_encode64(signature)}"
      end

      # Check if a token has expired without verifying the signature.
      #
      # @param token [String] the token to check
      # @return [Boolean] true if the token has expired or has no expiration
      def expired?(token)
        encoded, _sig = split_token(token)
        parsed = JSON.parse(Base64.urlsafe_decode64(encoded))
        return false unless parsed.key?('exp')

        parsed['exp'] <= Time.now.to_i
      rescue JSON::ParserError
        raise MalformedToken, 'invalid payload encoding'
      end

      # Inspect token metadata without verifying the signature.
      #
      # @param token [String] the token to inspect
      # @return [Hash] with :data, :exp (Integer or nil), and :expired (Boolean)
      def peek(token)
        encoded, _sig = split_token(token)
        parsed = JSON.parse(Base64.urlsafe_decode64(encoded))
        exp = parsed['exp']
        {
          data: parsed['data'],
          exp: exp,
          expired: exp ? exp <= Time.now.to_i : false
        }
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

      def verify_signature!(encoded, sig, keys: nil)
        actual = Base64.urlsafe_decode64(sig)
        candidates = keys.nil? ? [@key] : keys
        raise InvalidSignature, 'signature mismatch' unless candidates.any? do |candidate|
          secure_compare(compute_signature_with(candidate, encoded), actual)
        end
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
        compute_signature_with(@key, payload)
      end

      def compute_signature_with(key, payload)
        OpenSSL::HMAC.digest(@algorithm, key, payload)
      end

      def secure_compare(val_a, val_b)
        OpenSSL.fixed_length_secure_compare(val_a, val_b)
      rescue ArgumentError
        false
      end
    end
  end
end
