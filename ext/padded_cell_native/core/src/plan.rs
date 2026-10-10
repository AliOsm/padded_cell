//! Run order. Tests stay grouped by class, as Minitest and Rails run them:
//! per-class setup such as fixtures loads once.
//!
//! 1. group tests by class, in order of first appearance;
//! 2. keep the classes whose FNV-1a 64 hash modulo `shard_count` is
//!    `shard_index`;
//! 3. Fisher-Yates shuffle the classes, then each class's tests, with one
//!    [`SplitMix64`] seeded by `seed`;
//! 4. within a class, slowest test first; classes, slowest total first. Sorts
//!    are stable, so ties keep the shuffled order. A negative duration means
//!    unknown and counts as the median of the known ones (0.0 when none are
//!    known).

use std::cmp::Ordering;
use std::collections::HashMap;

use crate::hash::fnv1a64;
use crate::rng::SplitMix64;

#[cfg(test)]
mod tests;

/// Batches of test indices, one per class, in run order, for one shard.
///
/// `classes[i]` is the class of test `i` and `durations[i]` its last known run
/// time in seconds, or any negative number when unknown.
///
/// # Panics
///
/// When `shard_count` is 0, or `durations` is shorter than `classes`.
#[must_use]
pub fn plan<S: AsRef<[u8]>>(
    classes: &[S],
    durations: &[f64],
    seed: u64,
    shard_index: u64,
    shard_count: u64,
) -> Vec<Vec<usize>> {
    let mut batches = group(classes, shard_index, shard_count);
    let mut rng = SplitMix64::new(seed);
    shuffle(&mut batches, &mut rng);
    for batch in &mut batches {
        shuffle(batch, &mut rng);
    }

    let mut known = Vec::with_capacity(classes.len());
    known.extend(batches.iter().flatten().map(|&test| durations[test]).filter(|d| *d >= 0.0));
    let fallback = median(known);
    let estimate = |test: usize| {
        let duration = durations[test];
        if duration < 0.0 { fallback } else { duration }
    };
    let total = |batch: &[usize]| batch.iter().fold(0.0, |sum, &test| sum + estimate(test));

    // Stable sorts: ties keep the shuffled order.
    for batch in &mut batches {
        batch.sort_by(|&a, &b| descending(estimate(a), estimate(b)));
    }
    batches.sort_by(|a, b| descending(total(a), total(b)));
    batches
}

/// The tests of each class in this shard, classes in order of first
/// appearance. Each class is hashed once.
fn group<S: AsRef<[u8]>>(classes: &[S], shard_index: u64, shard_count: u64) -> Vec<Vec<usize>> {
    let mut slots: HashMap<&[u8], Option<usize>> = HashMap::new();
    let mut batches: Vec<Vec<usize>> = Vec::new();
    for (test, class) in classes.iter().enumerate() {
        let class = class.as_ref();
        let slot = *slots.entry(class).or_insert_with(|| {
            (fnv1a64(class) % shard_count == shard_index).then(|| {
                batches.push(Vec::new());
                batches.len() - 1
            })
        });
        if let Some(batch) = slot {
            batches[batch].push(test);
        }
    }
    batches
}

fn descending(a: f64, b: f64) -> Ordering {
    b.total_cmp(&a)
}

fn shuffle<T>(items: &mut [T], rng: &mut SplitMix64) {
    for i in (1..items.len()).rev() {
        let bound = u64::try_from(i + 1).unwrap_or(u64::MAX);
        // Below i + 1, so it fits.
        let j = usize::try_from(rng.next_u64() % bound).unwrap_or(i);
        items.swap(i, j);
    }
}

/// The median of the known durations, 0.0 without any. Selection, not a
/// full sort: the value is the same.
fn median(mut known: Vec<f64>) -> f64 {
    let len = known.len();
    if len == 0 {
        return 0.0;
    }
    let (lower, &mut upper, _) = known.select_nth_unstable_by(len / 2, f64::total_cmp);
    if !len.is_multiple_of(2) {
        return upper;
    }
    let below = lower.iter().copied().max_by(f64::total_cmp).unwrap_or(upper);
    below.midpoint(upper)
}
