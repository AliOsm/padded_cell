# frozen_string_literal: true

require 'minitest/autorun'

raise 'this file does not load'

# Never loaded, only discovered.
class BrokenTest < Minitest::Test
  def test_found
    flunk
  end

  def test_also_found
    flunk
  end
end
