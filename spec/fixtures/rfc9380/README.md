# RFC 9380 hash to curve vectors

The `BLS12381G1_XMD:SHA-256_SSWU_RO_` and `BLS12381G2_XMD:SHA-256_SSWU_RO_` suite vectors of
RFC 9380, appendix J.9.1 and J.10.1. Taken unmodified from `poc/vectors` of
[cfrg/draft-irtf-cfrg-hash-to-curve](https://github.com/cfrg/draft-irtf-cfrg-hash-to-curve),
renamed only to keep the colon out of the filename.

Run by `spec/bls/rfc9380_vectors_spec.rb`.

Each of the five vectors per suite carries the intermediate values as well as the result:
`u` from hash_to_field, `Q0` and `Q1` from map_to_curve, and `P` after cofactor clearing. For
G2 the spec walks all of them, so a discrepancy points at the stage that caused it rather than
just at the output. For G1 only `P` is checked, since hash_to_field and the map live in the
h2c gem.

The tag these carry, `QUUX-V01-CS02-with-<suite>`, is the document's own and belongs to no
signature scheme, so the spec passes it through `hash_to_curve`'s `dst:` argument. `msg` is a
plain byte string rather than hex.
