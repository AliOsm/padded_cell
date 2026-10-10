use super::*;

const UNKNOWN: f64 = -1.0;

fn classes(tests: usize, classes: usize) -> Vec<String> {
    (0..tests).map(|test| format!("Suite{}Test", test % classes)).collect()
}

#[test]
fn every_test_lands_in_exactly_one_shard_with_its_class() {
    let classes = classes(200, 23);
    let durations = vec![UNKNOWN; classes.len()];
    let shards: Vec<Vec<Vec<usize>>> =
        (0..4).map(|shard| plan(&classes, &durations, 7, shard, 4)).collect();
    let mut seen: Vec<usize> = shards.iter().flatten().flatten().copied().collect();
    seen.sort_unstable();
    assert_eq!(seen, (0..classes.len()).collect::<Vec<_>>());
    for batch in shards.iter().flatten() {
        assert!(batch.iter().all(|&test| classes[test] == classes[batch[0]]), "{batch:?}");
    }
    assert_eq!(shards.iter().flatten().count(), 23, "one batch per class");
}

#[test]
fn the_seed_decides_the_order() {
    let classes = classes(50, 5);
    let durations = vec![UNKNOWN; classes.len()];
    let first = plan(&classes, &durations, 42, 0, 1);
    assert_eq!(first, plan(&classes, &durations, 42, 0, 1));
    assert_ne!(first, plan(&classes, &durations, 43, 0, 1));
}

#[test]
fn slowest_class_and_test_first_unknown_counts_as_the_median() {
    // A: 1.0 + 3.0; B: 5.0; C: unknown, the median of 1.0, 3.0, 5.0 = 3.0.
    let classes = ["A", "A", "B", "C"];
    let durations = [1.0, 3.0, 5.0, UNKNOWN];
    assert_eq!(plan(&classes, &durations, 0, 0, 1), [vec![2], vec![1, 0], vec![3]]);
}

#[test]
fn pinned_order() {
    // Same input, same expected batches in test/plan_test.rb: the engines
    // agree even without the native extension.
    let classes = ["A", "B", "A", "C", "B", "A", "D", "C"];
    let durations = [0.5, UNKNOWN, 0.5, 2.0, UNKNOWN, 0.1, UNKNOWN, 0.5];
    assert_eq!(
        plan(&classes, &durations, 1234, 0, 1),
        [vec![3, 7], vec![2, 0, 5], vec![1, 4], vec![6]]
    );
    let unknown = [UNKNOWN; 8];
    assert_eq!(plan(&classes, &unknown, 1234, 0, 3), [vec![6], vec![0, 5, 2], vec![1, 4]]);
    assert_eq!(plan(&classes, &unknown, 1234, 1, 3), Vec::<Vec<usize>>::new());
    assert_eq!(plan(&classes, &unknown, 1234, 2, 3), [vec![3, 7]]);
}

#[test]
fn nothing_to_plan() {
    let classes: [&str; 0] = [];
    assert_eq!(plan(&classes, &[], 0, 0, 1), Vec::<Vec<usize>>::new());
}
