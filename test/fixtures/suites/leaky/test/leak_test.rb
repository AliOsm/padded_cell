# frozen_string_literal: true

require 'minitest/autorun'

# Order-dependent on purpose: test_reads fails after test_writes when both run
# in the same process.
class LeakTest < Minitest::Test
  def test_writes
    $leaked = true
    assert true
  end

  def test_reads
    refute $leaked
  end
end
