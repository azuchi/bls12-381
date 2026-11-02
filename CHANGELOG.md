## [Unreleased]

### Fixed

- `PointG2.from_hex` now rejects a coordinate at or above the field order. A coordinate written as `c + P` used to decode to the same point as `c`, giving one point several encodings.
- `expand_message_xmd`, and so `hash_to_curve` with a custom `dst:`, handles a domain separation tag longer than 255 bytes by hashing it as RFC 9380 section 5.3.3 prescribes, instead of failing inside I2OSP.
- Raising a field element to a negative power raises `ArgumentError`; `Fp2`, `Fp6` and `Fp12` used to answer with one.
- `expand_message_xmd` computes exactly the blocks RFC 9380 asks for. It used to compute one more, which cost a SHA-256 per call and failed outright at the largest permitted length.
- `==` on `Fp2`, `Fp6` and `Fp12` returns false for anything that is not the same kind of element instead of raising `NoMethodError`.
- `==` on a point returns false for a point of the other group, nil or anything else that is not a point of the same group, instead of raising `BLS::PointError`.
- `BLS.pairing` refuses a point outside the prime-order subgroup with `BLS::PointError`; it used to check only that the point was on the curve.

### Changed

- Scalar multiplication sizes its wNAF window table from the 255 bits of the group order rather than the base field, reduces the scalar modulo the order first, and skips zero windows instead of adding a throwaway point. `multiply` on G2 runs about three times faster and precompute tables shrink to a third.
- Subgroup membership (`in_group?`, and so `from_hex`) uses the endomorphism tests of Scott's "A note on group membership tests for G1, G2 and GT on BLS pairing-friendly curves" in place of a multiplication by the group order.
- `BLS::PointG1::MAX_BITS` and `BLS::PointG2::MAX_BITS` are gone; `BLS::ProjectivePoint::SCALAR_BITS` holds the width that matters.
- `BLS.norm_p1` and `BLS.norm_p2`, which nothing used, are gone.
- The `bigdecimal` dependency is gone.
- Requires Ruby 3.3 or later, matching what is tested.
- Depend on h2c 0.4.x, which no longer defines a top-level `BLS` module of its own.
- `hash_to_curve` refuses an empty or non-string `dst:` with `BLS::Error` for both groups, as RFC 9380 section 3.1 requires, and anything the h2c gem raises for G1 arrives as `BLS::PointError` rather than `H2C::Error`.

## [0.4.0] - 2026-08-10

- Check that every parsed point lies in the prime-order subgroup.
- Add the proof of possession scheme: `scheme:` on `sign`, `verify` and `verify_batch`, plus `pop_prove`, `pop_verify` and `fast_aggregate_verify`.
- `verify_batch` handles repeated messages correctly and refuses them under `:basic`.
- Verification returns false for the point at infinity instead of raising.
- Validate G1 encodings as strictly as G2: infinity padding, flag and length consistency, reduced coordinates.
- Validate hex input for points, messages and private keys instead of silently truncating or aliasing it.
- `Field#invert` raises on zero instead of returning zero.
- Fix `sgn0` to consult the second coordinate when the first is zero.
- All exceptions descend from `BLS::Error`, with `BLS::PointError` and `BLS::PairingError` beneath it.
- Add the bls12-381-tests and RFC 9380 test vectors. Document that nothing here is constant time.

## [0.3.1] - 2026-04-24

- Ruby 3.4 compatibility: depend on `bigdecimal` explicitly, follow the h2c gem's SSWU rename.

## [0.3.0] - 2023-07-21

- Support the compressed PointG2 format.
- Fix the private key range check.

## [0.2.2] - 2023-01-26

- Add `BLS::Field#==` and `BLS::Field#to_s`.

## [0.2.1] - 2023-01-16

- Add argument validation and error message cleanup.

## [0.2.0] - 2022-09-07

- Add `BLS::PointG2.from_private_key`.

## [0.1.0] - 2021-03-29

- Initial release
