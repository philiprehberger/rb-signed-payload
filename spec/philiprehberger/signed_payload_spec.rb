# frozen_string_literal: true

require "spec_helper"

RSpec.describe Philiprehberger::SignedPayload do
  let(:key) { "test-secret-key-123" }
  let(:data) { { "user" => "alice", "role" => "admin" } }

  describe ".sign and .verify" do
    it "round-trips data through sign and verify" do
      token = described_class.sign(data, key: key)
      result = described_class.verify(token, key: key)
      expect(result).to eq(data)
    end
  end

  describe Philiprehberger::SignedPayload::Signer do
    subject(:signer) { described_class.new(key: key) }

    describe "#sign and #verify" do
      it "returns the original data" do
        token = signer.sign(data)
        expect(signer.verify(token)).to eq(data)
      end

      it "produces a dot-separated token" do
        token = signer.sign(data)
        expect(token).to include(".")
        expect(token.split(".").length).to eq(2)
      end
    end

    describe "#verify" do
      it "raises InvalidSignature for tampered payload" do
        token = signer.sign(data)
        parts = token.split(".")
        tampered = "#{parts[0]}x.#{parts[1]}"
        expect { signer.verify(tampered) }.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
      end

      it "raises InvalidSignature with a different key" do
        token = signer.sign(data)
        other = described_class.new(key: "wrong-key")
        expect { other.verify(token) }.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
      end

      it "raises MalformedToken for garbage input" do
        expect { signer.verify("notavalidtoken") }.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
      end

      it "raises MalformedToken for empty string" do
        expect { signer.verify("") }.to raise_error(Philiprehberger::SignedPayload::MalformedToken)
      end
    end

    describe "expiration" do
      it "verifies a non-expired token" do
        token = signer.sign(data, expires_in: 3600)
        expect(signer.verify(token)).to eq(data)
      end

      it "raises ExpiredToken for an expired token" do
        token = signer.sign(data, expires_in: 1)
        sleep(1.1)
        expect { signer.verify(token) }.to raise_error(Philiprehberger::SignedPayload::ExpiredToken)
      end
    end

    describe "algorithm support" do
      it "round-trips with SHA384" do
        signer384 = described_class.new(key: key, algorithm: :sha384)
        token = signer384.sign(data)
        expect(signer384.verify(token)).to eq(data)
      end

      it "round-trips with SHA512" do
        signer512 = described_class.new(key: key, algorithm: :sha512)
        token = signer512.sign(data)
        expect(signer512.verify(token)).to eq(data)
      end

      it "rejects a token signed with sha256 when verified with sha512" do
        signer256 = described_class.new(key: key, algorithm: :sha256)
        signer512 = described_class.new(key: key, algorithm: :sha512)
        token = signer256.sign(data)
        expect { signer512.verify(token) }.to raise_error(Philiprehberger::SignedPayload::InvalidSignature)
      end
    end

    describe "#valid?" do
      it "returns true for a valid token" do
        token = signer.sign(data)
        expect(signer.valid?(token)).to be true
      end

      it "returns false for a tampered token" do
        token = signer.sign(data)
        tampered = "#{token}x"
        expect(signer.valid?(tampered)).to be false
      end

      it "returns false for an expired token" do
        token = signer.sign(data, expires_in: 1)
        sleep(1.1)
        expect(signer.valid?(token)).to be false
      end
    end

    describe "#decode" do
      it "returns the payload without verification" do
        token = signer.sign(data)
        expect(signer.decode(token)).to eq(data)
      end

      it "returns the payload even with a different key" do
        token = signer.sign(data)
        other = described_class.new(key: "wrong-key")
        expect(other.decode(token)).to eq(data)
      end
    end
  end

  describe ".valid?" do
    it "returns true for a valid token" do
      token = described_class.sign(data, key: key)
      expect(described_class.valid?(token, key: key)).to be true
    end

    it "returns false for a tampered token" do
      token = described_class.sign(data, key: key)
      expect(described_class.valid?("#{token}x", key: key)).to be false
    end
  end

  describe ".decode" do
    it "returns the payload without verification" do
      token = described_class.sign(data, key: key)
      expect(described_class.decode(token)).to eq(data)
    end
  end
end
