# frozen_string_literal: true

module PaddedCell
  # Process lifecycle hooks, for anything that must not be shared across
  # forks (database connections, sockets, per-worker resources):
  #
  #   PaddedCell.before_fork { Database.disconnect }
  #   PaddedCell.after_fork { |worker| Database.connect("app_test_#{worker}") }
  #   PaddedCell.cleanup { |worker| Database.drop("app_test_#{worker}") }
  #
  # before_fork runs in the runner before workers start, after_fork in each
  # worker (worker index 0...jobs) and cleanup when a worker finishes.
  # Cells (one fork per test) run no hooks: they inherit their worker.
  module Hooks
    @before_fork = []
    @after_fork = []
    @cleanup = []

    class << self
      def before_fork(&block) = @before_fork << block

      def after_fork(&block) = @after_fork << block

      def cleanup(&block) = @cleanup << block

      def run_before_fork = @before_fork.each(&:call)

      def run_after_fork(worker) = @after_fork.each { it.call(worker) }

      def run_cleanup(worker) = @cleanup.each { it.call(worker) }
    end
  end
end
