# frozen_string_literal: true

module Philiprehberger
  module SignedPayload
    class Error < StandardError; end
    class InvalidSignature < Error; end
    class ExpiredToken < Error; end
    class MalformedToken < Error; end
  end
end
