# frozen_string_literal: true

module Fast
  class UUID
    class Error < StandardError; end

    # A String that is not a UUID in the RFC 9562 canonical form.
    class ParseError < Error; end
  end
end
