# frozen_string_literal: true

require 'fileutils'

module PaddedCell
  # Seconds per test id from earlier runs, kept as "id<TAB>seconds" lines.
  # The scheduler starts the slowest tests first.
  module Timings
    module_function

    def load(path)
      return {} unless path && File.file?(path)

      File.foreach(path, chomp: true).to_h do |line|
        id, seconds = line.split("\t", 2)
        [id, Float(seconds)]
      end
    end

    # Replaces the file atomically.
    def save(path, timings)
      return unless path

      FileUtils.mkdir_p(File.dirname(path))
      temp = "#{path}.#{Process.pid}"
      File.write(temp, timings.sort.map { |id, seconds| "#{id}\t#{seconds}\n" }.join)
      File.rename(temp, path)
    end
  end
end
