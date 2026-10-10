use super::*;

#[test]
fn matches_the_reference_sequence() {
    // From Vigna's reference implementation, seed 1234567.
    let mut rng = SplitMix64::new(1_234_567);
    let expected = [
        6_457_827_717_110_365_317,
        3_203_168_211_198_807_973,
        9_817_491_932_198_370_423,
        4_593_380_528_125_082_431,
        16_408_922_859_458_223_821,
    ];
    for value in expected {
        assert_eq!(rng.next_u64(), value);
    }
}
