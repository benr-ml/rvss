
# research_rvss

Prototype implementation and benchmarking harness supporting the paper
**"Reconstructable VSS and High Threshold DKG of Field Elements"**.

> [!WARNING]
> **This is a research prototype, written to measure performance.** It has not been
> audited, it is not constant-time, it does not implement every check the paper specifies,
> and it must not be used in production or to protect anything of value.

Quick commands for building and running the benchmarks.

## Setup

The baseline implementations under `external/` are git submodules pinned at upstream
commits, and our modifications to them live in `patches/`. Run this once after cloning:

```
./scripts/setup-external.sh
```

> **Native execution is preferred and is what all reported benchmarks use.** Every number  is measured by running `cargo bench` directly on the host (a single machine, single-threaded, `RAYON_NUM_THREADS=1`).

## RVSS (this repo)

```
# happy path (Share/Verify), recovery gadget, and unhappy/Byzantine path
RAYON_NUM_THREADS=1 cargo bench --bench rvss
```

Benchmark groups: `ops` (single exponentiation), `gadget` (recovery gadget create/verify),
`rvss` (Share/Verify/decrypt), and `unhappy` (fraud-proof create, verify t+1 fraud proofs,
interpolation in the exponent, gadget decryption).

To switch the curve being tested (BLS12-381 <-> curve25519/ristretto255), comment/uncomment
the marked lines near the top of `src/rvss.rs`.

## Baselines (under `external/`)

See `external/README.md` for the upstream URL, pinned commit, and local
modifications of each baseline.

> **Build/run environment.** Run all benchmarks single-threaded for comparable timings, and
> on Apple Silicon (arm64 macOS) point the class-group builds at Homebrew GMP/OpenSSL.
> Export these once before running the baselines below:
> ```
> export RAYON_NUM_THREADS=1
> export CPATH=/opt/homebrew/include CPLUS_INCLUDE_PATH=/opt/homebrew/include
> export LIBRARY_PATH=/opt/homebrew/lib:/opt/homebrew/opt/openssl@3/lib
> export RUSTFLAGS="-L /opt/homebrew/lib -L /opt/homebrew/opt/openssl@3/lib"
> ```
> Without the include/lib paths the class-group builds (`cgdkg_artifact`,
> `cgdkg_artifact_blst`) fail with `gmp.h not found`. On Linux with system GMP/OpenSSL the
> path variables are unnecessary (keep `RAYON_NUM_THREADS=1`). `e2e-vss` additionally needs a
> C compiler (for `blstrs`) and network access at build time (it pulls a few git
> dependencies).

### cgVSS / GrothVSS (MIRACL backend) — `external/cgdkg_artifact`

The original (MIRACL) implementation; used for the in-text backend comparison and the
GrothVSS transcript size:

```
cd external/cgdkg_artifact
cargo bench --bench benchmarks_cgdkg --bench benchmarks_grothdkg
```

(The repo's plain `cargo bench` additionally runs `benchmarks_cd_dkg`, which we do not use.)
Depends on GMP; upstream also ships a `Dockerfile` if you would rather not install it, though
the reported numbers are all from native runs.

### cgVSS (blstrs backend) — `external/cgdkg_artifact_blst`

A fork with a blstrs (BLS12-381) class-group backend.

```
cd external/cgdkg_artifact_blst
cargo bench --bench benchmarks_pvss     # Criterion group "classgroup-pvss"
```

The `classgroup-pvss` group times `deal` (dealing), `verify` (verification, no decryption),
and `decrypt_share` (per-share decryption) separately; sweep `n=[4..1024]`, `t≈2n/3`.
Source: `classgroup/src/pvss.rs` (`deal`, `verify`, `decrypt_share`).

### Golden — `external/golden-rs`

Pure-Rust (arkworks BLS12-381); no system libraries needed.

```
cd external/golden-rs
cargo bench -p golden-dkg --bench dkg
# add the message-size bench too:
cargo bench -p golden-dkg --bench dkg --features borsh
```

Relevant Criterion IDs: `evrf_prove_single` / `evrf_verify_single` (dealing / verification
cores), `dkg_e2e/dkg/n=<n>_t=<t>` (end-to-end dealing + complete), `message_size_n5_t3`
(message size, `--features borsh`). Source: `golden-dkg/src/dkg.rs`.

### fast-Groth21 / e2e-vss — `external/e2e-vss`


```
cd external/e2e-vss/benches
cargo bench groth          # fast-Groth21 (primary baseline)
# other EXPTs: yurek | low-ed | low-bls | mix-ed | mix-bls | common
```

Relevant Criterion IDs: `groth/deal-<deg>/<n>` (dealing, `get_transcript`) and
`groth/verify-<t>/<n>` (verification, `verify_transcript`; share decryption is excluded to
match RVSS/cgVSS); sweep `t=[42,84,170,340,682]` (= 2n/3), `n=[64,128,256,512,1024]`.
Source: `acss/src/vss/groth_ni_acss.rs`.
