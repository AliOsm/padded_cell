# frozen_string_literal: true

require 'active_support/testing/parallelization'

module PaddedCell
  # Runs ActiveSupport's parallelization hooks around padded_cell's workers,
  # as Rails runs them around its own: parallelize_before_fork,
  # parallelize_setup, parallelize_teardown, and Active Record's per-worker
  # test databases (app_test-0, app_test-1...).
  #
  # The runner installs this after loading the tests when ActiveSupport::TestCase
  # is defined. Any parallelize(workers:) call in test_helper.rb stays inert:
  # padded_cell is the executor.
  module ActiveSupportHooks
    module_function

    def install
      return if @installed

      @installed = true
      parallelization = ActiveSupport::Testing::Parallelization
      PaddedCell.before_fork { parallelization.before_fork_hooks.each(&:call) }
      PaddedCell.after_fork do |worker|
        ActiveSupport::TestCase.parallel_worker_id = worker if ActiveSupport::TestCase.respond_to?(:parallel_worker_id=)
        parallelization.after_fork_hooks.each { it.call(worker) }
      end
      PaddedCell.cleanup { |worker| parallelization.run_cleanup_hooks.each { it.call(worker) } }
    end
  end
end
