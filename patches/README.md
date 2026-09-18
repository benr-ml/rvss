# Patches to the baseline repositories

Each `<name>.patch` here is a git-format diff against the commit at which
`external/<name>` is pinned (see [`../external/README.md`](../external/README.md) for the
upstream URL, pinned commit, license, and a prose description of every change).

Apply them with:

```
./scripts/setup-external.sh
```

Regenerate them after editing a baseline in place with:

```
./scripts/regen-patches.sh
```

Baselines with no patch file here (`cgdkg_artifact_blst`, `golden-rs`) are used exactly as
upstream published them.
