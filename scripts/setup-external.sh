#!/usr/bin/env bash
# Check out the pinned baseline repositories and apply our local modifications.
#
# The repos under external/ are git submodules pinned at the upstream commits listed
# in external/README.md. Our changes to them live in patches/ as git-format patches
# rather than as edited copies.
#
# Run this once after cloning. It is idempotent: re-running it on an already-patched
# tree is a no-op.
#
#   ./scripts/setup-external.sh
#
# NOTE: patches/fastcrypto.patch is required even for the RVSS benchmark alone --
# research_rvss depends on external/fastcrypto by path, and does not compile without it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Initialising submodules at their pinned commits"
git submodule update --init --recursive

for patch in patches/*.patch; do
    [ -e "$patch" ] || continue
    name="$(basename "$patch" .patch)"
    sub="external/$name"

    if [ ! -d "$sub/.git" ] && [ ! -f "$sub/.git" ]; then
        echo "!! $sub is not a checked-out submodule; skipping $patch" >&2
        exit 1
    fi

    if git -C "$sub" apply --reverse --check "$ROOT/$patch" >/dev/null 2>&1; then
        echo "==> $name: already patched, skipping"
    elif git -C "$sub" apply --check "$ROOT/$patch" >/dev/null 2>&1; then
        git -C "$sub" apply "$ROOT/$patch"
        echo "==> $name: patch applied"
    else
        echo "!! $name: patch does not apply cleanly to $(git -C "$sub" rev-parse --short HEAD)" >&2
        echo "   The submodule may not be at its pinned commit. Try:" >&2
        echo "     git submodule update --init --force -- $sub" >&2
        exit 1
    fi
done

echo
echo "Done. Baselines with no patch (cgdkg_artifact_blst, golden-rs) are used as-is."
echo "Build/run commands are in README.md."
