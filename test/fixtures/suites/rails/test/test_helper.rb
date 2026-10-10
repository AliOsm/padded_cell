# frozen_string_literal: true

require 'active_support'
require 'active_support/test_case'
require 'active_support/testing/autorun'

module ActiveSupport
  class TestCase
    # Inert under padded_cell, which is the executor; its hooks still run.
    parallelize(workers: 2)

    parallelize_setup { |worker| File.write(ENV.fetch('HOOK_LOG'), "setup #{worker}\n", mode: 'a') }
    parallelize_teardown { |worker| File.write(ENV.fetch('HOOK_LOG'), "teardown #{worker}\n", mode: 'a') }
  end
end
