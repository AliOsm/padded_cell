# frozen_string_literal: true

module Outer
  module Inner
    class Helper
      def test_not_in_a_test_class; end
    end

    class BaseTest < Minitest::Test
      def test_inherited
        assert true
      end

      class << self
        def test_singleton; end
      end

      class Nested
        def test_nested_non_test; end
      end

      class NestedTest < BaseTest
        def test_nested
          text = <<~RUBY
            def test_inside_heredoc
            end
          RUBY
          assert text
        end
      end

      def test_after_nested
        def test_def_inside_def; end
      end
    end
  end
end

class Something::Deep::ThingTest < Minitest::Test
  def test_deep; end
end

class dynamic::ThingTest < Minitest::Test
  def test_unknown_namespace; end
end

[1, 2].each do
  class LoopTest < Minitest::Test
    def test_in_block; end
  end
end

class Base < Struct.new(:a)
  def test_not_a_test_superclass; end
end

class LateTest < Object.const_get(:Minitest)::Test
  def test_dynamic_superclass; end
end
