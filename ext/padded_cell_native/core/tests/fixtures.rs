//! Every `tests/fixtures/*.rb` against its `.tsv` (class, name, start line,
//! end line). The Ruby suite checks the same files through the extension in
//! `test/discover_test.rb`.

use std::fs;
use std::path::{Path, PathBuf};

#[test]
fn fixtures_match_their_expectations() {
    let dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures");
    let mut fixtures: Vec<PathBuf> = fs::read_dir(&dir)
        .expect("fixtures directory")
        .map(|entry| entry.expect("fixture entry").path())
        .filter(|path| path.extension().is_some_and(|extension| extension == "rb"))
        .collect();
    fixtures.sort();
    assert!(fixtures.len() >= 5, "only {} fixtures in {}", fixtures.len(), dir.display());

    let found = padded_cell::discover_files(&fixtures).expect("readable fixtures");
    for (path, discovery) in fixtures.iter().zip(&found) {
        let tsv = fs::read_to_string(path.with_extension("tsv")).expect("expectations");
        let rows: Vec<String> = discovery
            .iter()
            .map(|test| {
                format!(
                    "{}\t{}\t{}\t{}",
                    test.class_name, test.name, test.start_line, test.end_line
                )
            })
            .collect();
        assert_eq!(rows, tsv.lines().collect::<Vec<_>>(), "{}", path.display());
    }
}
