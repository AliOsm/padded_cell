# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'valid user' do
    assert true
  end

  test 'knows its worker' do
    assert_kind_of Integer, ActiveSupport::TestCase.parallel_worker_id
  end

  def test_plain_method
    assert true
  end
end
