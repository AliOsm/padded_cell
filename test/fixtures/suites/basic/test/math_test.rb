# frozen_string_literal: true

require 'test_helper'

class MathTest < Minitest::Test
  def test_addition
    assert_equal 4, 2 + 2
  end

  def test_failure
    assert_equal 5, 2 + 2
  end

  def test_error
    raise 'boom'
  end

  def test_skip
    skip 'later'
  end
end
