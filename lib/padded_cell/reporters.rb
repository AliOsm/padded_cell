# frozen_string_literal: true

require 'fileutils'
require 'json'

module PaddedCell
  # File reporters for CI, next to Minitest's own console output.
  module Reporters
    # Collects results, writes them all at the end.
    class FileReporter < Minitest::AbstractReporter
      def initialize(path)
        super()
        @path = path
        @results = []
      end

      def record(result) = @results << result

      def report
        FileUtils.mkdir_p(File.dirname(@path))
        File.write(@path, render(@results))
      end

      private

      def status(result)
        return :skipped if result.skipped?
        return :error if result.error?

        result.passed? ? :passed : :failed
      end

      def file_and_line(result)
        file, line = result.source_location
        [relative(file.to_s), line]
      end

      def relative(file) = file.delete_prefix("#{Dir.pwd}/")
    end

    # JUnit XML, as read by GitHub, GitLab, Jenkins and friends.
    class JUnit < FileReporter
      ESCAPES = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&apos;' }.freeze
      # XML 1.0 has no place for most control characters.
      INVALID = /[^\t\n\r -\u{D7FF}\u{E000}-\u{FFFD}\u{10000}-\u{10FFFF}]/

      private

      def render(results)
        suites = results.group_by(&:klass).map { |klass, cases| suite(klass, cases) }
        %(<?xml version="1.0" encoding="UTF-8"?>\n<testsuites name="padded_cell" #{counts(results)}>\n) +
          suites.join + "</testsuites>\n"
      end

      def suite(klass, results)
        %(  <testsuite name="#{escape(klass)}" #{counts(results)}>\n) +
          results.map { testcase(it) }.join + "  </testsuite>\n"
      end

      def counts(results)
        statuses = results.map { status(it) }
        %(tests="#{results.size}" failures="#{statuses.count(:failed)}" errors="#{statuses.count(:error)}" ) +
          %(skipped="#{statuses.count(:skipped)}" time="#{format('%.6f', results.sum(&:time))}")
      end

      def testcase(result)
        file, line = file_and_line(result)
        attributes = %(classname="#{escape(result.klass)}" name="#{escape(result.name)}" file="#{escape(file)}" ) +
                     %(line="#{line}" time="#{format('%.6f', result.time)}" assertions="#{result.assertions}")
        body = outcome(result)
        body.empty? ? %(    <testcase #{attributes}/>\n) : %(    <testcase #{attributes}>\n#{body}    </testcase>\n)
      end

      def outcome(result)
        failure = result.failure
        case status(result)
        when :skipped then %(      <skipped message="#{escape(failure.message)}"/>\n)
        when :error, :failed
          tag = status(result) == :error ? 'error' : 'failure'
          type = failure.is_a?(Minitest::UnexpectedError) ? failure.error.class : failure.class
          %(      <#{tag} type="#{escape(type.to_s)}" message="#{escape(failure.message.lines.first.to_s.strip)}">) +
            %(#{escape(failure.message)}</#{tag}>\n)
        else ''
        end
      end

      def escape(text) = text.to_s.scrub.gsub(INVALID, '').gsub(/[&<>"']/, ESCAPES)
    end

    # One JSON object per test, one per line.
    class JSONLines < FileReporter
      private

      def render(results) = results.map { "#{JSON.generate(entry(it))}\n" }.join

      def entry(result)
        file, line = file_and_line(result)
        {
          id: "#{result.klass}##{result.name}", class: result.klass, name: result.name, file:, line:,
          status: status(result), time: result.time, assertions: result.assertions,
          failures: result.failures.map { { type: it.result_label, message: it.message.scrub } }
        }
      end
    end
  end
end
