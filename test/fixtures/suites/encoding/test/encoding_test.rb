# frozen_string_literal: true

require 'minitest/autorun'

# Rails sets this, and Ruby then transcodes whatever is written to a
# text-mode IO, binary or not.
Encoding.default_internal = Encoding::UTF_8

class EncodingTest < Minitest::Test
  # A name this long puts bytes >= 0x80 in the Marshal'd result.
  define_method(:"test_#{'long_name_' * 20}") { assert true }

  def test_binary_failure_message
    assert_equal "\xFF\xFE".b, 'x'
  end
end
