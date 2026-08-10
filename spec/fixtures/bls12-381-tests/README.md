# bls12-381-tests

Vendored from [ethereum/bls12-381-tests](https://github.com/ethereum/bls12-381-tests) release
`v0.1.2` (`bls_tests_json.tar.gz`), unmodified. Released under CC0 1.0 Universal.

Run by `spec/bls/eth_vectors_spec.rb`.

The signature handlers use the proof of possession ciphersuite,
`BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_`, so public keys are G1 points and signatures
are G2 points: `scheme: :pop` with the library's default `sig_type`/`key_type`.

`hash_to_G2` is the exception. Its vectors are the RFC 9380 ones, and they carry that
document's own tag, `QUUX-V01-CS02-with-BLS12381G2_XMD:SHA-256_SSWU_RO_`, which belongs to no
signature scheme. The spec passes it through `hash_to_curve`'s `dst:` argument. Its `msg` is a
plain byte string rather than hex, unlike every other handler here.

An `output` of `null` marks an input with no valid result, such as signing with a zero private
key. This library raises `BLS::Error` for those.
