use super::*;

#[test]
fn matches_the_reference_values() {
    let cases: &[(&str, u64)] = &[
        ("", 0xcbf2_9ce4_8422_2325),
        ("a", 0xaf63_dc4c_8601_ec8c),
        ("foobar", 0x8594_4171_f739_67e8),
    ];
    for (input, expected) in cases {
        assert_eq!(fnv1a64(input.as_bytes()), *expected, "input: {input:?}");
    }
}
