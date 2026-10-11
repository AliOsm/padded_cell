# frozen_string_literal: true

require 'minitest/autorun'
require 'padded_cell'

PaddedCell.cleanup { |worker| raise 'cleanup failed' if worker.zero? }

class CleanupTest < Minitest::Test
  2.times do |i|
    define_method(:"test_#{i}") { assert true }
  end
end
