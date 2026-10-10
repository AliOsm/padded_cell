# frozen_string_literal: true

require 'minitest/autorun'

# Error classes that exist only where the test ran, as with Rails
# autoloading an error class during a test: the runner never loaded them.
class LateTest < Minitest::Test
  def test_raises_a_class_defined_during_the_test
    Object.const_set(:LateError, Class.new(StandardError)) unless defined?(LateError)
    raise LateError, 'defined in the worker'
  end

  def test_raises_a_nested_class_defined_during_the_test
    Object.const_set(:Late, Module.new) unless defined?(Late)
    Late.const_set(:NestedError, Class.new(StandardError)) unless defined?(Late::NestedError)
    raise Late::NestedError, 'nested, defined in the worker'
  end

  def test_after_them
    assert true
  end
end
