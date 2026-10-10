# frozen_string_literal: true

require 'test_helper'

class StringTest < Minitest::Test
  def test_upcase
    assert_equal 'A', 'a'.upcase
  end

  def test_reverse
    assert_equal 'ba', 'ab'.reverse
  end
end
