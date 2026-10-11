# frozen_string_literal: true

require 'minitest/autorun'
require 'padded_cell'

# The test fails, then passes on retry. Only the retry's worker finds the
# marker saying so: its cleanup alone fails.
RETRIED = File.join(ENV.fetch('FLAKY_DIR'), 'retried')

PaddedCell.cleanup { raise 'retry cleanup failed' if File.exist?(RETRIED) && File.read(RETRIED) == 'passed' }

class RetryCleanupTest < Minitest::Test
  def test_passes_when_retried
    if File.exist?(RETRIED)
      File.write(RETRIED, 'passed')
      pass
    else
      File.write(RETRIED, 'failed')
      flunk 'lost the race'
    end
  end
end
