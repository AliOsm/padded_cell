# frozen_string_literal: true

class BrokenTest < Minitest::Test
  def test_before_the_error
    assert true
  end

  def test_unfinished(
    assert true
  end

  test 'after the error' do
    assert true
  end
