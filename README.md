# padded_cell

Your tests aren't crazy. They just need their own room.

padded_cell is a drop-in runner for Minitest and Rails test suites. Nothing in
your tests changes; padded_cell replaces the thing that runs them:

- **every test in its own forked cell**: a test that segfaults, calls `exit`,
  hangs, monkey patches `Time` or leaves a thread behind takes down its cell,
  not the run, and not the next test (Rails suites with fixtures default to
  sharing a worker instead, see [Isolation](#isolation));
- **workers fed whole classes**, slowest first from the timings of the
  previous run, so per-class setup such as fixtures happens once; idle
  workers split the remaining big classes;
- **static discovery** with Prism: `file:line`, `--list` and CI sharding work
  without loading a single test file;
- Minitest's own reporters and plugins, plus JUnit XML and JSON lines.

Discovery and scheduling are Rust, in a native extension: Prism parses the
test files on every core, and a deterministic scheduler orders the run.

```console
$ bundle exec padded_cell
Run options: --seed 33512 --isolation test

# Running:

.....E.......................................

Finished in 2.083220s, 21.6013 runs/s, 233.2927 assertions/s.

  1) Error:
PaymentTest#test_refund:
PaddedCell::CellCrashed: cell killed by SIGABRT
    test/models/payment_test.rb:41:in 'PaymentTest#test_refund'

45 runs, 486 assertions, 0 failures, 1 errors, 0 skips
```

One test segfaulted a C extension (Ruby aborts on a segfault) and took its cell
down. The other 44 never noticed.

## Installation

Requires CRuby 4.0 or newer and Minitest 6, on Linux, macOS or FreeBSD.
padded_cell is built on `fork`: Windows, JRuby and TruffleRuby are not
supported.

```ruby
group :test do
  gem "padded_cell"
end
```

Precompiled gems ship for Linux (x86_64 and aarch64; glibc 2.34+ such as
Debian 13, Ubuntu 26.04, RHEL 10, Fedora, Arch or Omarchy, plus musl for
Alpine), macOS 13+ (arm64, x86_64) and FreeBSD 15.1 (amd64): no Rust, no
compiler, nothing to build. Anything else (another CPU, an older glibc) gets
the source gem, which compiles the extension at install and needs Rust 1.99+.
padded_cell does not load without its extension.

## Usage

```console
$ padded_cell                              # test/**/*_test.rb, minus system, dummy and fixtures
$ padded_cell test/models                  # a directory
$ padded_cell test/models/user_test.rb:12  # the test spanning line 12
$ padded_cell user_test.rb:12-30:41        # tests overlapping 12..30, or spanning 41
$ padded_cell -n /refund/ -e test_slow     # Minitest's --include / --exclude
$ padded_cell -j 8 --seed 1234             # 8 workers, reproducible order
$ padded_cell --timeout 30                 # kill and fail anything running 30s
$ padded_cell --fail-fast
$ padded_cell --list                       # what would run, without loading anything
$ padded_cell --shard 2/4                  # CI: the second quarter of the classes
$ padded_cell --junit tmp/junit.xml --json tmp/results.jsonl
```

Exit status: 0 when everything passed, 1 otherwise, 2 for usage or load
errors, 130 when interrupted.

### How a run works

1. **Select** files the way `rails test` does, `file:line` included.
2. **Discover** tests statically with Prism (`def test_*` and Rails'
   `test "..."` in classes inheriting from a `...Test` or `...TestCase`).
3. **Load** the test files once, in the runner. Workers and cells are forks of
   that process, so the app boots once, and copy-on-write shares its memory.
   `minitest/autorun` is neutralized, so the suite does not run again at exit.
4. **Order**: keep each class's tests together, as Minitest and Rails do.
   Shard by a stable hash of the class name, shuffle classes and tests with
   the seed, then put the slowest classes, and within them the slowest
   tests, first (`tmp/padded_cell/timings.tsv`).
5. **Run**: a worker takes a whole class; once no class is left to take, an
   idle worker splits off the second half of another worker's remainder.
   Each test sends back its `Minitest::Result`. A cell or worker that dies or
   times out becomes an error result.
6. **Report** through Minitest's own reporters and plugins.

Loaded tests are the source of truth: inherited, `define_method` and other
dynamic tests run even though static discovery cannot see them.

### Isolation

`--isolation test` forks a cell per test. Forking a preloaded process is
cheap, and order-dependent tests stop depending on order.

`--isolation worker` runs tests directly in the long-lived workers, like
Rails' `parallelize`. A worker that crashes or times out is still reported
and replaced.

The default is `test`, except when Active Record fixtures are loaded: a fork
discards Active Record's connection pool, and every test would reload its
fixtures, so those suites default to `worker`. The `Run options:` line shows
which one a run uses; `--isolation` overrides it.

### Hooks

For anything that must not be shared across forks:

```ruby
# test/test_helper.rb
PaddedCell.before_fork { Database.disconnect }
PaddedCell.after_fork { |worker| Database.connect("app_test_#{worker}") }
PaddedCell.cleanup { |worker| Database.drop("app_test_#{worker}") }
```

`before_fork` runs in the runner, `after_fork` and `cleanup` once per worker
(`0...jobs`). Cells run no hooks: they inherit their worker's state.

## Rails

Nothing to configure. ActiveSupport's parallelization hooks run around
padded_cell's workers as they would around Rails' own: `parallelize_setup`,
`parallelize_teardown`, `parallelize_before_fork`, and Active Record's
per-worker test databases (`app_test-0`, `app_test-1`...).
`ActiveSupport::TestCase.parallel_worker_id` is set. A
`parallelize(workers: ...)` call in `test_helper.rb` stays inert, since
padded_cell is the executor.

```console
$ bin/rails padded_cell ARGS="-j 8 test/models"
```

Rails suites with fixtures run with `--isolation worker` unless told
otherwise (see [Isolation](#isolation)).

Coverage tools that write their results from an `at_exit` hook (SimpleCov)
see only the runner, as with Rails' process parallelization.

## Library

The engine-backed parts load without Minitest:

```ruby
require "padded_cell"

PaddedCell::Discovery.call(Dir["test/**/*_test.rb"]).map { [it.id, it.lines] }
# => [["UserTest#test_valid", 10..12], ...]

PaddedCell::Scheduler.batches(class_names, durations: seconds, seed: 42, shard: [0, 4])
# => [[test indices of one class], ...] in run order
```

## Rust

The extension lives in `ext/padded_cell_native`: `core` does discovery and
scheduling in plain Rust (no Ruby types), `ffi` binds it to Ruby. Neither is
published as a crate.

## Development

Needs Rust 1.99+ (`mise install` reads `mise.toml`).

```console
bundle install
rake test:all        # cargo test, then the Ruby suite (compiles the extension first)
rake test            # the Ruby suite only
rake dogfood         # this suite, run by padded_cell
rake lint            # dictator, cargo fmt --check, clippy
```

## License

MIT
