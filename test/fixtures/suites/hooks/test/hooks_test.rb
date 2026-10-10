# frozen_string_literal: true

require 'minitest/autorun'
require 'padded_cell'

PaddedCell.after_fork { |worker| File.write(ENV.fetch('HOOK_LOG'), "after_fork #{worker}\n", mode: 'a') }
PaddedCell.cleanup { |worker| File.write(ENV.fetch('HOOK_LOG'), "cleanup #{worker}\n", mode: 'a') }

class HooksTest < Minitest::Test
  8.times do |i|
    define_method(:"test_#{i}") { assert true }
  end
end
