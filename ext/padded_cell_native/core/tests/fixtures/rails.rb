# frozen_string_literal: true

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    test 'index lists users' do
      get admin_users_url
      assert_response :success
    end

    test "odd  whitespace\tand\nnewlines" do
      assert true
    end

    test 'no block'

    test "interpolated #{1 + 1}" do
      assert true
    end

    test :symbol do
      assert true
    end

    test 'two', 'arguments' do
      assert true
    end

    self.test 'explicit receiver' do
      assert true
    end

    test('parenthesized') { assert true }
  end
end

class ::TopLevelTest < ActiveSupport::TestCase
  test 'absolute name' do
    assert true
  end
end

class Admin::NestedPathTest < ApplicationSystemTestCase
  def test_path; end
end
