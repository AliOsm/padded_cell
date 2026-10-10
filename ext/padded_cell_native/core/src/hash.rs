//! FNV-1a 64. Shards split on it: unlike std's randomly seeded hasher, it is
//! stable across runs, processes and machines, so CI shards agree.

#[cfg(test)]
mod tests;

/// The FNV-1a 64-bit hash of `bytes`.
#[must_use]
pub fn fnv1a64(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf2_9ce4_8422_2325, |hash, &byte| {
        (hash ^ u64::from(byte)).wrapping_mul(0x0000_0100_0000_01b3)
    })
}
