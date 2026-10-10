# frozen_string_literal: true

module PaddedCell
  # Deterministic run order: tests grouped by class, shards of whole classes,
  # seeded shuffle, slowest classes (and tests) first.
  module Scheduler
    UNKNOWN = -1.0

    module_function

    # Batches of test indices, one per class, in run order, for one shard.
    #
    #   classes:   class name of each test
    #   durations: seconds per test (nil when unknown)
    #   shard:     [index, count], 0-based
    def batches(classes, durations: Array.new(classes.size), seed: 0, shard: [0, 1])
      index, count = shard
      PaddedCellNative.plan(classes, durations.map { it || UNKNOWN }, seed, index, count)
    end
  end
end
