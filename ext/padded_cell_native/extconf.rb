# frozen_string_literal: true

# padded_cell's discovery and scheduling are Rust: without the extension
# the gem cannot work, so a missing toolchain stops the install with the reason.
def fail_native(reason)
  abort "padded_cell: #{reason}. padded_cell needs its native extension; precompiled gems exist for " \
        'Linux (glibc 2.34+, musl), macOS 13+ and FreeBSD 15.1.'
end

def command?(command) = system(command, out: File::NULL, err: File::NULL)

# rb_sys writes a GNU Makefile; RubyGems runs the system make (BSD make here).
BSD = RUBY_PLATFORM.include?('bsd')

fail_native("#{RUBY_ENGINE} is not supported (CRuby only)") unless RUBY_ENGINE == 'ruby'
fail_native('Cargo not found (install Rust 1.99+ from https://rustup.rs)') unless command?('cargo --version')
fail_native('GNU make not found (pkg install gmake)') if BSD && !command?('gmake --version')

require 'mkmf'
require 'rb_sys/mkmf'

create_rust_makefile('padded_cell/padded_cell_native') do |r|
  r.ext_dir = 'ffi'
  r.profile = ENV.fetch('RB_SYS_CARGO_PROFILE', :release).to_sym
end

# BSD make reads BSDmakefile first (GNU make ignores it): delegate to gmake.
if BSD
  File.write('BSDmakefile', <<~MAKE)
    GMAKE_VARS =
    .for var in DESTDIR sitearchdir sitelibdir
    .if defined(${var})
    GMAKE_VARS += ${var}="${${var}}"
    .endif
    .endfor

    # BSD make exports its own job flags (-J) in MAKEFLAGS; gmake rejects them.
    GMAKE = env -u MAKEFLAGS -u MFLAGS gmake -f Makefile

    all:
    \t${GMAKE} ${GMAKE_VARS}

    .DEFAULT:
    \t${GMAKE} ${GMAKE_VARS} $@
  MAKE
end
