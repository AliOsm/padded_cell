# padded_cell

Static Minitest discovery and deterministic test scheduling: the Rust core of
the padded_cell gem's native extension (`../ffi` binds it to Ruby). Internal,
not published. It has no Ruby types: parse test files with
[Prism](https://github.com/ruby/prism) and plan a sharded, seeded,
longest-first run.

```rust
let source = br#"
class UsersControllerTest < ActionDispatch::IntegrationTest
  test "index lists users" do
    get users_url
  end

  def test_show
  end
end
"#;

let found = padded_cell::discover(source);
let ids: Vec<String> = found.iter().map(|test| test.id()).collect();
assert_eq!(ids, ["UsersControllerTest#test_index_lists_users", "UsersControllerTest#test_show"]);
let first = found.iter().next().ok_or("no test")?;
assert_eq!((first.start_line, first.end_line), (3, 5));
assert_eq!(found.classes(), ["UsersControllerTest"]); // stored once

// One batch per class, slowest first. Shard 1 of 2, seed 42, no timings yet
// (-1.0 means unknown).
let classes: Vec<&str> = found.iter().map(|test| test.class_name).collect();
let batches = padded_cell::plan(&classes, &[-1.0, -1.0], 42, 0, 2);
assert!(batches.iter().flatten().all(|&index| index < ids.len()));
# Ok::<(), Box<dyn std::error::Error>>(())
```

- `discover` finds `def test_*` methods and Rails `test "..."` declarations in
  classes whose superclass ends in `Test` or `TestCase`, with their line
  spans. Nothing is evaluated, and syntax errors do not stop it. Each class
  name is stored once; tests borrow it.
- `discover_files` reads and parses many files across cores, on scoped
  threads (a process can fork right after). `discover_many` does the same for
  sources already in memory.
- `plan` keeps tests grouped by class (per-class setup such as fixtures loads
  once), shards classes by FNV-1a hash, shuffles with SplitMix64, and puts
  the slowest classes, and within them the slowest tests, first. Class names
  are any bytes (`AsRef<[u8]>`).

## License

MIT
