# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'

class NativeTest < Minitest::Test
  LIB = File.expand_path('../lib', __dir__)

  def test_version_matches_the_gem
    assert_equal PaddedCell::VERSION, PaddedCellNative.version
  end

  # There is no pure Ruby fallback: without its extension, padded_cell says
  # why instead of half-working.
  def test_missing_extension_fails_loudly
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(LIB, dir)
      Dir[File.join(dir, 'lib', '**', "padded_cell_native.#{RbConfig::CONFIG['DLEXT']}")].each { File.delete(it) }
      # --disable-gems: an installed padded_cell must not stand in for the missing build.
      _out, err, status = Open3.capture3(RbConfig.ruby, '--disable-gems', '-I', File.join(dir, 'lib'),
                                         '-rpadded_cell', '-e', '')

      refute_predicate status, :success?
      assert_includes err, 'padded_cell: native extension not loaded'
    end
  end
end
