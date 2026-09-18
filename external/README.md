# Baseline repositories

Each directory here is a **git submodule pinned at an upstream commit**.

Our changes to the baselines live in [`../patches/`](../patches) as git-format patches and
are applied by [`../scripts/setup-external.sh`](../scripts/setup-external.sh):

```
./scripts/setup-external.sh
```

Run that once after cloning. It is required even if you only want the RVSS benchmark:
`research_rvss` depends on `external/fastcrypto` by path and does not compile without
`patches/fastcrypto.patch`.

| Directory | Upstream | Pinned commit | License | Patch |
|---|---|---|---|---|
| `cgdkg_artifact` | [hsaleemsupra/cgdkg_artifact](https://github.com/hsaleemsupra/cgdkg_artifact) | `bb43549` | GPL-3.0 | `patches/cgdkg_artifact.patch` |
| `cgdkg_artifact_blst` | [alinush/cgdkg_artifact](https://github.com/alinush/cgdkg_artifact) | `387b327` | GPL-3.0 | — (unmodified) |
| `fastcrypto` | [MystenLabs/fastcrypto](https://github.com/MystenLabs/fastcrypto) | `52a012c` | Apache-2.0 | `patches/fastcrypto.patch` |
| `golden-rs` | [farazshaikh/golden-rs](https://github.com/farazshaikh/golden-rs) | `09f892b` | not stated upstream | — (unmodified) |
| `e2e-vss` | [sourav1547/e2e-vss](https://github.com/sourav1547/e2e-vss) | `9b08f15` | not stated upstream | `patches/e2e-vss.patch` |

Build and benchmark commands for each baseline are in the top-level [`README.md`](../README.md).

To change a baseline, edit it in place under `external/<name>/` and then run
`./scripts/regen-patches.sh` to refresh the patch file.

## What the patches do

### `patches/fastcrypto.patch`

1. `fastcrypto/src/groups/bls12381.rs` — adds `impl HashToGroupElement for Scalar` (hash a
   message to a BLS12-381 field element), used for the Fiat-Shamir challenge in the RVSS
   low-degree NIZK and in the self-implemented DLEQ fraud proof.
2. `fastcrypto-tbls/src/dl_verification.rs` — `verify_pairs` gains a `base: &G` parameter
   (was hardcoded to `G::generator()`) so the recovery gadget can batch-verify exponents
   against the non-generator base `h`.

Both sites are marked with an `RVSS modification:` comment.

### `patches/cgdkg_artifact.patch`

Used to produce the `cgVSS` (MIRACL backend) and `GrothVSS` baseline numbers.

1. `benches/benchmarks_cgdkg.rs`, `benches/benchmarks_grothdkg.rs`,
   `benches/benchmarks_cd_dkg.rs` — the `DkgConfig` sweep was changed from upstream's
   `n = {50, 100, 150, 200}` to `n = {64, 128, 256, 512, 1024}` with `t ≈ 2n/3` (e.g.
   64/42 … 1024/682), to match the party counts used in the paper.
2. `benches/benchmarks_cgdkg.rs`, `benches/benchmarks_cd_dkg.rs` — the receiver-side share
   decryption call `let _pt = decrypt(&cl, &sks[0], &dealing.ciphertexts[0]);` is commented
   out and the benchmark relabeled `"VSS: Receiver Time (verify_sharing)"` (upstream:
   `"... (verify_sharing + decrypt_share)"`). In `benchmarks_grothdkg.rs` the receiver
   benchmark is `"VSS Receiver Time (verify_sharing + verify_chunking)"`. Hence the baseline
   verification numbers exclude class-group share decryption — this is the "verification
   without decryption" reported in the paper's comparison figure.
3. All three files — the `"DKG: Compute per node (dealer_cost + t * verifier_cost +
   agg_dealings)"` benchmark block is commented out; only the Sender (dealing) and Receiver
   (verify) timings remain.
4. `Dockerfile` — cosmetic reordering of the `WORKDIR`/`COPY` lines; no functional change.

### `patches/e2e-vss.patch`

Used to produce the `fast-Groth21` baseline numbers.

1. `benches/src/groth_ni_acss.rs` — the threshold sweep `ts` was changed from upstream's low
   threshold `t = n/3 = [21, 42, 85, 170, 341]` to the high threshold `t = (n/3)*2 =
   [42, 84, 170, 340, 682]` (i.e. `2n/3`), matching the polynomial degree used by RVSS and
   cgVSS so the dealing/verification comparison is apples-to-apples (`deg = t`,
   `SharingConfiguration::new(deg+1, n)`). `ns = [64,128,256,512,1024]` is unchanged
   (already matches the paper). Marked with an `RVSS modification:` comment.
2. `benches/src/groth_ni_acss.rs` — in `vss_verify`, the `dec_chunks(...)` call (share
   decryption) is commented out so the `groth/verify-<t>/<n>` benchmark measures verification
   only (`verify_transcript`), matching RVSS.Verify and the cgVSS verify benchmarks, which
   all exclude decryption. (Upstream bundled decryption into the verify timing.) The
   now-unused `dec_chunks` import is also commented out. Marked with an
   `RVSS modification:` comment.
3. `Cargo.lock` — `blst` bumped from `0.3.11` to `0.3.16` (latest), via
   `cargo update -p blst --precise 0.3.16`, within the existing `blstrs` 0.6.x. This brings
   e2e-vss to the same blst version as fastcrypto and `cgdkg_artifact_blst`.
4. `cli/Cargo.toml`, `crypto/Cargo.toml` — `group` dependency bumped from `0.12.0` to
   `0.12.1` so the workspace resolves against the updated lockfile.
