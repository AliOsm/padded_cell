# frozen_string_literal: true

require 'test_helper'

class UserTest < Minitest::Test
  def setup
    @user = Object.new
  end

  def test_valid
    assert @user
  end

  def test_predicate?
    assert true
  end

  def self.test_class_method_is_not_a_test; end

  def helper; end

  private

  # Minitest only runs public methods; static discovery cannot tell.
  def test_private_still_listed
    assert true
  end
end

class NotATest
  def test_ignored; end
end
