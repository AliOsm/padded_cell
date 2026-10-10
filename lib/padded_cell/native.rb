# frozen_string_literal: true

# Loads the Rust extension, which does discovery and scheduling. There is no
# fallback: platform gems ship it precompiled under the Ruby ABI version, the
# source gem compiles it at install, and a checkout builds it with
# `rake compile`.

require 'rbconfig'

shipped = File.join(__dir__, RUBY_VERSION[/\A\d+\.\d+/], "padded_cell_native.#{RbConfig::CONFIG['DLEXT']}")
begin
  File.exist?(shipped) ? require(shipped) : require('padded_cell/padded_cell_native')
rescue LoadError => e
  raise LoadError, "padded_cell: native extension not loaded (#{e.message}). Precompiled gems need " \
                   'glibc 2.34+ (Linux), macOS 13+ or FreeBSD 15.1; elsewhere the gem builds it with Rust ' \
                   'at install. In a checkout, run `rake compile`.'
end

# A stale build may implement other semantics.
unless PaddedCellNative.version == PaddedCell::VERSION
  raise LoadError, "padded_cell: native extension #{PaddedCellNative.version} does not match padded_cell " \
                   "#{PaddedCell::VERSION}: rebuild it (`rake compile` in a checkout, or reinstall the gem)"
end
