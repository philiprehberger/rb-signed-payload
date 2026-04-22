# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::SignedPayload do
  let(:key) { 'test-secret-key-123' }
  let(:data) { { 'user' => 'alice', 'role' => 'admin' } }

  describe '.sign and .verify' do
    it 'round-trips data through sign and verify' do
      token = described_class.sign(data, key: key)
      result = described_class.verify(token, key: key)
      expect(result).to eq(data)
    end
  end

  describe Philiprehberger::SignedPayload::Signer do
    subject(:signer) { described_class.new(key: key) }

    describe '#sign and #verify' do
      it 'returns the original data' do
        token = signer.sign(data)
        expect(signer.verify(token)).to eq(data)
      end

      it 'produces a dot-separated token' do
        token = signer.sign(data)
        expect(token).to include('.')
        expect(token.split('.').length).to eq(2)
      end
    end

    describe '#verify' do
      it 'raises InvalidSignature for tampered payload' do
        token = signer.sign(data)
        parts = token.split('.')
        tampered = "#{parts[0]}x.#{parts[1]}"
        expect { signer.verify(tampered) }.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
      end

      it 'raises InvalidSignature with a different key' do
        token = signer.sign(data)
        other = described_class.new(key: 'wrong-key')
        expect { other.verify(token) }.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
      end

      it 'raises MalformedToken for garbage input' do
        expect { signer.verify('notavalidtoken') }.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
      end

      it 'raises MalformedToken for empty string' do
        expect { signer.verify('') }.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
      end
    end

    describe 'expiration' do
      it 'verifies a non-expired token' do
        token = signer.sign(data, expires_in: 3600)
        expect(signer.verify(token)).to eq(data)
      end

      it 'raises ExpiredToken for an expired token' do
        token = signer.sign(data, expires_in: 1)
        sleep(1.1)
        expect { signer.verify(token) }.to raise_error(Philiprehberger::SignedPayload::ExpiredToken)
      end
    end

    describe 'algorithm support' do
      it 'round-trips with SHA384' do
        signer384 = described_class.new(key: key, algorithm: :sha384)
        token = signer384.sign(data)
        expect(signer384.verify(token)).to eq(data)
      end

      it 'round-trips with SHA512' do
        signer512 = described_class.new(key: key, algorithm: :sha512)
        token = signer512.sign(data)
        expect(signer512.verify(token)).to eq(data)
      end

      it 'rejects a token signed with sha256 when verified with sha512' do
        signer256 = described_class.new(key: key, algorithm: :sha256)
        signer512 = described_class.new(key: key, algorithm: :sha512)
        token = signer256.sign(data)
        expect { signer512.verify(token) }.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
      end
    end

    describe '#valid?' do
      it 'returns true for a valid token' do
        token = signer.sign(data)
        expect(signer.valid?(token)).to be true
      end

      it 'returns false for a tampered token' do
        token = signer.sign(data)
        tampered = "#{token}x"
        expect(signer.valid?(tampered)).to be false
      end

      it 'returns false for an expired token' do
        token = signer.sign(data, expires_in: 1)
        sleep(1.1)
        expect(signer.valid?(token)).to be false
      end
    end

    describe '#decode' do
      it 'returns the payload without verification' do
        token = signer.sign(data)
        expect(signer.decode(token)).to eq(data)
      end

      it 'returns the payload even with a different key' do
        token = signer.sign(data)
        other = described_class.new(key: 'wrong-key')
        expect(other.decode(token)).to eq(data)
      end
    end
  end

  describe '.valid?' do
    it 'returns true for a valid token' do
      token = described_class.sign(data, key: key)
      expect(described_class.valid?(token, key: key)).to be true
    end

    it 'returns false for a tampered token' do
      token = described_class.sign(data, key: key)
      expect(described_class.valid?("#{token}x", key: key)).to be false
    end
  end

  describe '.decode' do
    it 'returns the payload without verification' do
      token = described_class.sign(data, key: key)
      expect(described_class.decode(token)).to eq(data)
    end

    it 'raises MalformedToken for token with no dot' do
      expect { described_class.decode('nodot') }.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
    end

    it 'raises MalformedToken for token with multiple dots' do
      expect { described_class.decode('a.b.c') }.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
    end
  end

  describe '.refresh' do
    it 'returns a new token with the same data' do
      token = described_class.sign(data, key: key, expires_in: 3600)
      refreshed = described_class.refresh(token, key: key, expires_in: 7200)
      result = described_class.verify(refreshed, key: key)
      expect(result).to eq(data)
    end

    it 'raises for an invalid token' do
      expect { described_class.refresh('bad.token', key: key, expires_in: 3600) }.to raise_error(
        Philiprehberger::SignedPayload::InvalidSignature
      )
    end
  end

  describe '.rotate' do
    let(:old_key) { 'old-secret-key' }
    let(:new_key) { 'new-secret-key' }

    it 'returns a token that verifies under the new key' do
      token = described_class.sign(data, key: old_key)
      rotated = described_class.rotate(token, old_key: old_key, new_key: new_key)
      expect(described_class.verify(rotated, key: new_key)).to eq(data)
    end

    it 'produces a token that does not verify under the old key' do
      token = described_class.sign(data, key: old_key)
      rotated = described_class.rotate(token, old_key: old_key, new_key: new_key)
      expect { described_class.verify(rotated, key: old_key) }.to raise_error(
        Philiprehberger::SignedPayload::InvalidSignature
      )
    end

    it 'preserves the original data' do
      token = described_class.sign(data, key: old_key)
      rotated = described_class.rotate(token, old_key: old_key, new_key: new_key)
      expect(described_class.decode(rotated)).to eq(data)
    end

    it 'preserves the original expiration timestamp' do
      token = described_class.sign(data, key: old_key, expires_in: 3600)
      original_exp = described_class.peek(token)[:exp]
      rotated = described_class.rotate(token, old_key: old_key, new_key: new_key)
      expect(described_class.peek(rotated)[:exp]).to eq(original_exp)
    end

    it 'preserves absence of expiration' do
      token = described_class.sign(data, key: old_key)
      rotated = described_class.rotate(token, old_key: old_key, new_key: new_key)
      expect(described_class.peek(rotated)[:exp]).to be_nil
    end

    it 'raises InvalidSignature when old_key does not match' do
      token = described_class.sign(data, key: old_key)
      expect do
        described_class.rotate(token, old_key: 'wrong-key', new_key: new_key)
      end.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
    end

    it 'raises MalformedToken for garbage input' do
      expect do
        described_class.rotate('notavalidtoken', old_key: old_key, new_key: new_key)
      end.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
    end

    it 'supports non-default algorithms' do
      token = described_class.sign(data, key: old_key, algorithm: :sha512)
      rotated = described_class.rotate(token, old_key: old_key, new_key: new_key, algorithm: :sha512)
      expect(described_class.verify(rotated, key: new_key, algorithm: :sha512)).to eq(data)
    end
  end

  describe '.expired?' do
    it 'returns false for a non-expired token' do
      token = described_class.sign(data, key: key, expires_in: 3600)
      expect(described_class.expired?(token)).to be false
    end

    it 'returns true for an expired token' do
      token = described_class.sign(data, key: key, expires_in: 1)
      sleep(1.1)
      expect(described_class.expired?(token)).to be true
    end

    it 'returns false for a token with no expiration' do
      token = described_class.sign(data, key: key)
      expect(described_class.expired?(token)).to be false
    end
  end

  describe '.peek' do
    it 'returns data and expiration metadata' do
      token = described_class.sign(data, key: key, expires_in: 3600)
      info = described_class.peek(token)
      expect(info[:data]).to eq(data)
      expect(info[:exp]).to be_a(Integer)
      expect(info[:expired]).to be false
    end

    it 'returns nil exp for tokens without expiration' do
      token = described_class.sign(data, key: key)
      info = described_class.peek(token)
      expect(info[:exp]).to be_nil
      expect(info[:expired]).to be false
    end

    it 'works without verifying signature' do
      token = described_class.sign(data, key: key)
      info = described_class.peek(token)
      expect(info[:data]).to eq(data)
    end
  end

  describe 'empty and edge-case payloads' do
    it 'signs and verifies an empty hash' do
      token = described_class.sign({}, key: key)
      expect(described_class.verify(token, key: key)).to eq({})
    end

    it 'signs and verifies a nil payload' do
      token = described_class.sign(nil, key: key)
      expect(described_class.verify(token, key: key)).to be_nil
    end

    it 'signs and verifies a string payload' do
      token = described_class.sign('hello', key: key)
      expect(described_class.verify(token, key: key)).to eq('hello')
    end

    it 'signs and verifies an integer payload' do
      token = described_class.sign(42, key: key)
      expect(described_class.verify(token, key: key)).to eq(42)
    end

    it 'signs and verifies an array payload' do
      token = described_class.sign([1, 2, 3], key: key)
      expect(described_class.verify(token, key: key)).to eq([1, 2, 3])
    end

    it 'signs and verifies a large payload' do
      large = { 'data' => 'x' * 10_000 }
      token = described_class.sign(large, key: key)
      expect(described_class.verify(token, key: key)).to eq(large)
    end
  end

  describe 'tamper detection' do
    it 'detects modified signature' do
      token = described_class.sign(data, key: key)
      parts = token.split('.')
      tampered = "#{parts[0]}.#{parts[1]}AA"
      expect { described_class.verify(tampered, key: key) }.to raise_error(
        Philiprehberger::SignedPayload::InvalidSignature
      )
    end

    it 'detects swapped payload with valid format' do
      token1 = described_class.sign({ 'a' => 1 }, key: key)
      token2 = described_class.sign({ 'b' => 2 }, key: key)
      parts1 = token1.split('.')
      parts2 = token2.split('.')
      franken = "#{parts1[0]}.#{parts2[1]}"
      expect { described_class.verify(franken, key: key) }.to raise_error(
        Philiprehberger::SignedPayload::InvalidSignature
      )
    end
  end

  describe 'unsupported algorithm' do
    it 'raises ArgumentError for unknown algorithm' do
      expect { described_class.sign(data, key: key, algorithm: :md5) }.to raise_error(ArgumentError)
    end
  end

  describe 'key sensitivity' do
    it 'fails verification with a key differing by one character' do
      token = described_class.sign(data, key: 'secret-key-A')
      expect { described_class.verify(token, key: 'secret-key-B') }.to raise_error(
        Philiprehberger::SignedPayload::InvalidSignature
      )
    end

    it 'fails verification with empty key vs non-empty key' do
      token = described_class.sign(data, key: 'real-key')
      expect { described_class.verify(token, key: '') }.to raise_error(
        Philiprehberger::SignedPayload::InvalidSignature
      )
    end
  end

  describe 'multi-key verify (zero-downtime rotation)' do
    let(:current_key) { 'current-secret' }
    let(:old_key) { 'old-secret' }
    let(:older_key) { 'older-secret' }

    it 'verifies when the correct key is first in the array' do
      token = described_class.sign(data, key: current_key)
      expect(described_class.verify(token, key: [current_key, old_key, older_key])).to eq(data)
    end

    it 'verifies when the correct key is last in the array (old keys before current)' do
      token = described_class.sign(data, key: current_key)
      expect(described_class.verify(token, key: [older_key, old_key, current_key])).to eq(data)
    end

    it 'raises InvalidSignature when none of the keys match' do
      token = described_class.sign(data, key: current_key)
      expect do
        described_class.verify(token, key: %w[wrong-a wrong-b wrong-c])
      end.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
    end

    it 'preserves single-key (String) behavior unchanged' do
      token = described_class.sign(data, key: current_key)
      expect(described_class.verify(token, key: current_key)).to eq(data)
    end

    it 'raises ArgumentError for an empty array of keys' do
      token = described_class.sign(data, key: current_key)
      expect { described_class.verify(token, key: []) }.to raise_error(ArgumentError, /no keys provided/)
    end

    it 'honors the algorithm argument across candidate keys' do
      token = described_class.sign(data, key: current_key, algorithm: :sha512)
      expect(
        described_class.verify(token, key: [old_key, current_key], algorithm: :sha512)
      ).to eq(data)
    end

    it 'raises ExpiredToken when a candidate key matches but the token is expired' do
      token = described_class.sign(data, key: current_key, expires_in: 1)
      sleep(1.1)
      expect do
        described_class.verify(token, key: [old_key, current_key])
      end.to raise_error(Philiprehberger::SignedPayload::ExpiredToken)
    end

    describe 'Signer#verify with keys:' do
      it 'accepts a keys: array on the Signer instance' do
        signer = Philiprehberger::SignedPayload::Signer.new(key: current_key)
        token = signer.sign(data)
        other = Philiprehberger::SignedPayload::Signer.new(key: 'placeholder')
        expect(other.verify(token, keys: [old_key, current_key])).to eq(data)
      end

      it 'raises ArgumentError on an empty keys: array' do
        signer = Philiprehberger::SignedPayload::Signer.new(key: current_key)
        token = signer.sign(data)
        expect { signer.verify(token, keys: []) }.to raise_error(ArgumentError, /no keys provided/)
      end
    end
  end
end
