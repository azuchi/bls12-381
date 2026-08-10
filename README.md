# BLS12-381 for Ruby [![Build Status](https://github.com/azuchi/bls12-381/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/azuchi/bls12-381/actions/workflows/main.yml/badge.svg?branch=main) [![Gem Version](https://badge.fury.io/rb/bls12-381.svg)](https://badge.fury.io/rb/bls12-381) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)

This library is a Ruby BLS12-381 implementation based on the JavaScript implementation [noble-bls12-381](https://github.com/paulmillr/noble-bls12-381).
In addition to that, it is possible to switch between public key and signature group (G1 and G2).

Note: This library has passed the same tests as noble-bls12-381, but has not been audited to prove its safety.
Please be careful when using this, and read [Side channels](#side-channels) before signing with it.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bls12-381'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bls12-381

## Usage

```ruby
require 'bls'

# Generate private key.
private_key = SecureRandom.random_number(BLS::Curve::R - 1)

# Or you can use hex string.
private_key = '67d53f170b908cabb9eb326c3c337762d59289a8fec79f7bc9254b584b73265c'

# Generate public key from private key.
public_key = BLS.get_public_key(private_key)
# Public key is BLS::PointG1 object.
# If you want to use BLS::PointG2 public key, use BLS.get_public_key(p, key_type: :g2)

# sign and verify
message = '64726e3da8'

signature = BLS.sign(message, private_key)
# signature is BLS::PointG2 object. You can get signature with hex format using #to_hex method.
# If you want to use BLS::PointG1 signature, use BLS.sign(message, p, sig_type: :g1)
signature.to_signature

is_correct = BLS.verify(signature, message, public_key)
=> true

private_keys = [
  '18f020b98eb798752a50ed0563b079c125b0db5dd0b1060d1c1b47d4a193e1e4',
  'ed69a8c50cf8c9836be3b67c7eeff416612d45ba39a5c099d48fa668bf558c9c',
  '16ae669f3be7a2121e17d0c68c05a8f3d6bef21ec0f2315f1d7aec12484e4cf5'
]
public_keys = private_keys.map { |p| BLS.get_public_key(p) }

# Sign 3 msgs with 3 keys
messages = %w[d2 0d98 05caf3]
signatures3 = private_keys.map.with_index { |p, i| BLS.sign(messages[i], p)}
agg_signatures3 = BLS.aggregate_signatures(signatures3)
is_correct3 = BLS.verify_batch(agg_signatures3, messages, public_keys)
=> true

# Sign 1 msg with 3 keys.
# This needs the proof of possession scheme: see the warning below.
proofs = private_keys.map { |p| BLS.pop_prove(p) }
public_keys.zip(proofs).each { |pubkey, proof| raise 'invalid key' unless BLS.pop_verify(pubkey, proof) }

signatures2 = private_keys.map { |p| BLS.sign(message, p, scheme: :pop) }
agg_signatures2 = BLS.aggregate_signatures(signatures2)
is_correct2 = BLS.fast_aggregate_verify(agg_signatures2, message, public_keys)
=> true
```

## Signature schemes

This library implements two of the schemes of
[draft-irtf-cfrg-bls-signature](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-bls-signature-05),
selected with the `scheme:` keyword of `BLS.sign` / `BLS.verify` / `BLS.verify_batch`.
They use different domain separation tags, so a signature made under one never verifies
under the other. The default is `:basic`, which is what earlier versions of this gem used.

| scheme | aggregation |
| --- | --- |
| `:basic` (default) | `BLS.verify_batch`, **only when every message is distinct** |
| `:pop` | the above with no such restriction, plus `BLS.fast_aggregate_verify` for many signatures over a single message |

`BLS.verify_batch` returns `false` for a `:basic` aggregate that covers the same message
twice, however well formed the signature is. Pass `scheme: :pop` to verify those.

**Aggregating public keys is unsafe without proofs of possession.** Given a public key
`pk_victim`, an attacker can register `pk_attacker = g * x - pk_victim` for an `x` they
choose. The two keys aggregate to `g * x`, so the attacker alone can produce a signature
that verifies against the aggregate, making it look like the victim signed. This is the
rogue key attack, and it is why `:basic` supports no single-message aggregation at all.

`BLS.pop_prove` closes the hole by signing a key with itself: producing a proof requires
the private key, which the attacker does not have for `pk_attacker`. Call `BLS.pop_verify`
on every public key **before** passing it to `BLS.aggregate_public_keys` or
`BLS.fast_aggregate_verify` — neither of them can do it for you, since they never see the
proofs.

## Errors

Everything this library raises about the data it was handed descends from `BLS::Error`, so
one rescue covers a key that will not parse, a point outside the subgroup, a private key that
is not hex, and a pairing that is not defined:

```ruby
begin
  public_key = BLS::PointG1.from_hex(untrusted)
rescue BLS::Error => e   # BLS::PointError here, and BLS::PairingError elsewhere
  ...
end
```

Passing the wrong type or the wrong number of coefficients is a mistake in the calling code
rather than a fact about a key, and raises `ArgumentError` as it would anywhere else in Ruby.

Verification never raises over the data it is given. `BLS.verify`, `BLS.verify_batch`,
`BLS.fast_aggregate_verify` and `BLS.pop_verify` return `false` for anything they will not
accept, including the point at infinity and an empty set of signers, so untrusted input cannot
turn into an exception. Deserializing that input with `from_hex` beforehand still raises, which
is where a malformed encoding is caught.

## Threads

Signing and verifying from several threads gives the right answers, but two caches are
written without a lock and neither is worth sharing a point over.

`calc_multiply_precomputes` builds its table over long enough that MRI switches threads part
way through, so callers racing on one point all pass the "already has precomputes" check and
each build their own. They build the same table, so the result stays correct; what you lose is
the time and the memory of doing it several times over, and a guard that reads as protection
while providing none. Build the table once, before the point goes anywhere else.

`BLS.verify` memoises pairing coefficients onto the G2 point it is given, and onto
`BLS::PointG2::BASE` when the public key is a G2 point. Racing callers recompute rather than
corrupt, for the same reason: what is assigned is always a finished array.

## Side channels

**Nothing here is constant time, and signing is not safe against an attacker who can
measure it.** `BLS.sign` and `BLS.get_public_key` multiply a curve point by the private
key, and that multiplication leaks:

* the scalar picks which precomputed point each window adds, so it decides which memory
  gets touched, which is visible through the cache;
* point addition returns early when an operand is the identity or the two are equal;
* underneath it all, Ruby's bignum arithmetic and the `%` in `BLS::Fp` take time that
  depends on their operands.

A pure Ruby implementation cannot fix this: it has no control over how the interpreter
lays out or times its integers. Treat this gem as suitable where the private key operation
cannot be observed — verification of untrusted input is fine, since it touches no secret —
and use a binding to a constant time library such as [blst](https://github.com/supranational/blst)
where an attacker can watch the signer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BlS12-381 project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/bls12-381/blob/master/CODE_OF_CONDUCT.md).
