# frozen_string_literal: true

require 'minitest/autorun'

# Each test fails its first attempt for a known reason, deterministically:
# the runner tests pick the seed and the marker directory.
class FlakyTest < Minitest::Test
  # A cell seeds rand with the run's seed: the seed alone decides this one.
  def test_depends_on_the_seed
    assert_equal 0, rand(2), 'unlucky seed'
  end

  # Fails until its marker exists, like a race lost under load: run again
  # with the same seed, it passes.
  def test_passes_when_retried
    marker = File.join(ENV.fetch('FLAKY_DIR'), 'retried')
    if File.exist?(marker)
      assert true
    else
      File.write(marker, '')
      flunk 'lost the race'
    end
  end

  def test_always_fails
    flunk 'a real failure'
  end

  def test_fine
    assert true
  end
end
