# frozen_string_literal: true

require 'minitest/autorun'

class CrashTest < Minitest::Test
  def test_killed
    Process.kill(:KILL, Process.pid)
  end

  def test_exit_bang
    exit!(3)
  end

  def test_exit
    exit 4
  end

  def test_hangs
    sleep 30
  end

  def test_fine
    assert true
  end
end
