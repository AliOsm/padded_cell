# Changelog

## Unreleased

- `--asylum[=N]`: retry failed tests (N times, default 2) after the run,
  alone and in fresh cells. Tests that pass on retry count as passed and are
  reported as flaky, with the likely cause (timing and shared state, or
  randomness and order) and their first failure; JUnit gets
  `<flakyFailure>`, JSON a `flaky` field.

## 0.1.0 (2026-10-11)

First release, for CRuby 4.0+ and Minitest 6 on Linux, macOS and FreeBSD: a
drop-in runner for Minitest and Rails test suites. Windows, JRuby and
TruffleRuby are not supported.

- Fork-per-test cells (`--isolation test`) or long-lived workers
  (`--isolation worker`); crashes, `exit`, `exit!` and `--timeout` become
  error results, and dead workers are replaced.
- Static discovery with Prism: `file:line[-line]`, `--list` and `--shard I/N`
  without loading tests.
- Tests grouped by class (fixtures load once per class), seeded order,
  slowest classes and tests first from the previous run's timings; idle
  workers split big classes. `--shard` splits by class.
- Worker isolation by default when Active Record fixtures are loaded.
- Minitest's reporters and plugins, plus `--junit` and `--json` reports.
- `PaddedCell.before_fork` / `after_fork` / `cleanup` hooks; ActiveSupport's
  parallelization hooks and Active Record's per-worker test databases.
- Discovery and scheduling in Rust, as a native extension: precompiled gems
  for Linux, macOS and FreeBSD, a source gem that compiles it elsewhere.
