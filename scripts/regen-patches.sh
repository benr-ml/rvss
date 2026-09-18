#!/usr/bin/env bash
# Regenerate patches/*.patch from the current state of the submodule working trees.
#
# Use this after editing a baseline in place: make the change inside external/<name>/,
# then run this script to refresh the patch. A submodule whose working tree matches its
# pinned commit has its patch file removed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p patches

git config --file .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}' | while read -r sub; do
    name="$(basename "$sub")"
    out="patches/$name.patch"
    # --binary so the patch survives any non-text change; staged in the submodule's index
    # only transiently, then restored.
    git -C "$sub" add -A
    if git -C "$sub" diff --cached --quiet; then
        rm -f "$out"
        echo "==> $name: identical to pinned commit (no patch)"
    else
        git -C "$sub" diff --cached --binary > "$ROOT/$out"
        echo "==> $name: wrote $out ($(git -C "$sub" diff --cached --name-only | wc -l | tr -d ' ') files)"
    fi
    git -C "$sub" reset -q
done
