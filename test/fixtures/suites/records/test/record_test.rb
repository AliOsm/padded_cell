# frozen_string_literal: true

require 'minitest/autorun'

# MOCKED: stands in for Active Record's fixtures, whose presence makes
# padded_cell default to worker isolation.
module ActiveRecord
  class FixtureSet; end
end

class RecordTest < Minitest::Test
  def test_runs
    assert true
  end
end
