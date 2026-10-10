# frozen_string_literal: true

require 'etc'
require 'minitest'
require_relative '../padded_cell'
require_relative 'results'
require_relative 'cell'
require_relative 'pool'
require_relative 'loader'
require_relative 'timings'
require_relative 'reporters'

module PaddedCell
  # Running tests needs fork: Windows (and the JVM Rubies) are not supported.
  class Unsupported < StandardError; end

  # Runs a Minitest suite: select, discover, load once, order, fork, report.
  class Runner
    DEFAULTS = {
      paths: [], jobs: Etc.nprocessors, seed: nil, include: nil, exclude: nil, shard: [0, 1],
      isolation: nil, timeout: nil, fail_fast: false, verbose: false, show_skips: false,
      list: false, junit: nil, json: nil, timings: 'tmp/padded_cell/timings.tsv', io: $stdout
    }.freeze

    attr_reader :options

    def initialize(**options)
      @options = DEFAULTS.merge(options)
      @options[:seed] ||= (ENV['SEED'] || Random.new_seed).to_i % 0xFFFF
    end

    # Exit status: 0 when everything passed, 1 otherwise, 130 on Ctrl-C.
    def run
      selection = Selection.parse(options[:paths])
      refs = Discovery.call(selection.files)
      return list(selection, refs) if options[:list]
      raise Unsupported, 'padded_cell needs fork, which this Ruby does not have' unless Process.respond_to?(:fork)

      Loader.call(selection.files, seed: options[:seed])
      if defined?(ActiveSupport::TestCase)
        require_relative 'active_support_hooks'
        ActiveSupportHooks.install
      end
      options[:isolation] ||= default_isolation
      filter = Filter.new(selection, refs, include: options[:include], exclude: options[:exclude])
      execute(Loader.tests.select { filter.call(*it) })
    end

    private

    # A fork per test discards Active Record's connection pool, and with it
    # the fixtures loaded through it: every test would reload them. With
    # fixtures around, tests share their worker instead.
    def default_isolation = defined?(ActiveRecord::FixtureSet) ? :worker : :test

    # Tests as they would run (static discovery, no loading), in file order.
    def list(selection, refs)
      refs = refs.select { selection.covers?(it.file, it.lines) }
      kept = Scheduler.batches(refs.map(&:class_name), seed: options[:seed], shard: options[:shard]).flatten.sort
      kept.each do |index|
        ref = refs[index]
        options[:io].puts "#{ref.file.delete_prefix("#{Dir.pwd}/")}:#{ref.start_line} #{ref.id}"
      end
      0
    end

    def execute(tests)
      ids = tests.map { |klass, name| "#{klass}##{name}" }
      timings = Timings.load(options[:timings])
      batches = Scheduler.batches(tests.map { |klass, _| klass.to_s }, durations: ids.map { timings[it] },
                                                                      seed: options[:seed], shard: options[:shard])
      reporter = build_reporter
      reporter.start
      interrupted = dispatch(tests, batches, reporter) { |index, result| timings[ids[index]] = result.time }
      reporter.report
      Timings.save(options[:timings], timings)
      after_run
      finish(reporter, interrupted, batches.empty?)
    end

    # Yields each result after reporting it. True when interrupted.
    def dispatch(tests, batches, reporter)
      pool = nil
      on_result = lambda do |index, result|
        reporter.prerecord(*tests[index])
        reporter.record(result)
        yield index, result
        pool&.stop! if options[:fail_fast] && !result.passed? && !result.skipped?
      end
      pool = Pool.new(tests, jobs: options[:jobs], isolation: options[:isolation], seed: options[:seed],
                             timeout: options[:timeout])
      pool.run(batches, &on_result)
      false
    rescue Interrupt
      warn 'Interrupted. Exiting...'
      true
    end

    def build_reporter
      reporter = Minitest::CompositeReporter.new
      minitest_options = {
        io: options[:io], seed: options[:seed], args: "--seed #{options[:seed]} --isolation #{options[:isolation]}",
        verbose: options[:verbose], show_skips: options[:show_skips]
      }
      reporter << Minitest::SummaryReporter.new(options[:io], minitest_options)
      reporter << Minitest::ProgressReporter.new(options[:io], minitest_options)
      # Plugins (minitest-reporters, Rails...) may add or swap reporters.
      Minitest.reporter = reporter
      Minitest.init_plugins(minitest_options)
      Minitest.reporter = nil
      reporter << Reporters::JUnit.new(options[:junit]) if options[:junit]
      reporter << Reporters::JSONLines.new(options[:json]) if options[:json]
      reporter
    end

    # Minitest.after_run blocks, which autorun would have called.
    def after_run
      Minitest.class_variable_get(:@@after_run).reverse_each(&:call)
    end

    def finish(reporter, interrupted, nothing_ran)
      return 130 if interrupted
      if nothing_ran && options[:include]
        warn "Nothing ran for filter: #{options[:include]}"
        return 1
      end

      reporter.passed? ? 0 : 1
    end
  end
end
