# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'padded_cell'
require 'minitest/autorun'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Discovery fixtures shared with the Rust crate, and runnable test suites.
module Fixtures
  DISCOVERY = File.expand_path('../ext/padded_cell_native/core/tests/fixtures', __dir__)
  SUITES = File.expand_path('fixtures/suites', __dir__)

  # {"/abs/minitest.rb" => expected rows}
  def self.discovery
    @discovery ||= Dir[File.join(DISCOVERY, '*.rb')].sort.to_h do |path|
      rows = File.readlines(path.sub(/\.rb\z/, '.tsv'), chomp: true).map do |line|
        class_name, name, start_line, end_line = line.split("\t")
        [class_name, name, Integer(start_line), Integer(end_line)]
      end
      [path, rows]
    end
  end
end

# Runs exe/padded_cell in a fixture suite, in a subprocess.
module CLIHelper
  LIB = File.expand_path('../lib', __dir__)
  EXE = File.expand_path('../exe/padded_cell', __dir__)
  SUMMARY = /(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors, (\d+) skips/

  Run = Data.define(:out, :err, :status) do
    def exitstatus = status.exitstatus

    # [runs, assertions, failures, errors, skips]
    def summary = SUMMARY.match(out)&.captures&.map { Integer(it) }
  end

  def padded_cell(*args, suite:, env: {})
    command = [RbConfig.ruby, '-I', LIB, EXE, *args]
    Run.new(*Open3.capture3(env, *command, chdir: File.join(Fixtures::SUITES, suite)))
  end
end
