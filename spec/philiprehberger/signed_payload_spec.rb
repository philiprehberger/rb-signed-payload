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
  end
end
