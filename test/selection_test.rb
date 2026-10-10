# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'

class SelectionTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir
    %w[test/a_test.rb test/models/b_test.rb test/system/c_test.rb test/fixtures/d_test.rb
       test/helper.rb].each do |path|
      FileUtils.mkdir_p(File.dirname(File.join(@root, path)))
      File.write(File.join(@root, path), '')
    end
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def files(*args) = PaddedCell::Selection.parse(args, root: @root).files.map { it.delete_prefix("#{@root}/") }

  def test_defaults_skip_system_dummy_and_fixtures
    assert_equal %w[test/a_test.rb test/models/b_test.rb], files
  end

  def test_directories_globs_and_files
    assert_equal %w[test/system/c_test.rb], files('test/system')
    assert_equal %w[test/a_test.rb test/models/b_test.rb], files('test/**/[ab]_test.rb')
    assert_equal %w[test/a_test.rb], files('test/a_test.rb', 'test/a_test.rb')
  end

  def test_line_ranges
    selection = PaddedCell::Selection.parse(['test/a_test.rb:3-5:12', 'test/models/b_test.rb'], root: @root)
    a_test = File.join(@root, 'test/a_test.rb')

    assert_predicate selection, :line_filtered?
    assert_equal [3..5, 12..12], selection.lines_for(a_test)
    assert selection.covers?(a_test, 5..9)
    assert selection.covers?(a_test, 12..12)
    refute selection.covers?(a_test, 6..11)
    assert selection.covers?(File.join(@root, 'test/models/b_test.rb'), 1..1)
  end

  def test_missing_files_are_errors
    error = assert_raises(ArgumentError) { files('test/nope_test.rb:3') }

    assert_equal 'no such test file: test/nope_test.rb:3', error.message
  end
end
