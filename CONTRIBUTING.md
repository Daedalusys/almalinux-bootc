# Contributing

> **Quick orientation**: this is a fork of `AlmaLinux/bootc-images`, stripped to the `10-kitten` variant only. The fork ships a headless base image for [Daedalus](https://github.com/Daedalusys/daedalus-core). Read [`README.md`](README.md) and [`docs/REBASE.md`](docs/REBASE.md) before contributing.

## What this fork accepts

| Type | Accept? | Why |
|---|---|---|
| Manifest changes (add openssh-server, etc.) | YES — opens a PR | Documented in PR description |
| New postprocess scripts | YES — opens a PR | Run before merge via `tests/no-gui.sh` + `tests/rescue-path.sh` |
| Variant additions (e.g., `:10-server`) | NO | Fork is kitten-only by design (plan 2026-10-20 §R1) |
| Multi-arch support beyond `amd64`/`arm64` | YES | Currently only if upstream supports it |
| LICENSE changes | NO | Inherited from upstream GPL-3.0 (fork is copyleft) |
| Adding GUI packages | NO | Violates headless invariant (`tests/no-gui.sh` will fail) |

## Before opening a PR

Run the verification suite locally:

```bash
cd /home/lofibass/code/Daedalus/almalinux-bootc

# 1. Static: manifest has no GUI packages (no container needed)
just verify-headless-manifest

# 2. Static: published image has no GUI packages + rescue path is usable
just verify-headless

# 3. Static: HEADLESS_BASE_IMAGE consistency (daedalus-core consumer)
grep -q 'ghcr.io/daedalusys/almalinux-bootc' README.md
```

If any of these fail, the change violates a fork invariant — fix before PR.

The same checks run in CI — see [headless guarantees](#headless-guarantees).

## headless guarantees

Two guard scripts hold the headless invariants: `tests/no-gui.sh` checks that no GUI
package reached the image, `tests/rescue-path.sh` checks that the rescue path (sshd +
serial console) is usable. Both static sections run in CI, the live section runs rarely.

| Layer | Where | When | A red result |
|---|---|---|---|
| manifest scan | `build` job → `Verify headless invariants` | every build (amd64) | blocks the build, the image is not pushed |
| image probes | `verify-headless` job | after every build | its own status check, eligible for a required check |
| live probe | `verify-headless-live` job | `workflow_dispatch`, weekly cron | does not block a release, but every red result needs a look |

Reproduce locally — same entry points as CI:

```bash
just verify-headless                    # static sections, probes the published :10-kitten
IMAGE=ghcr.io/daedalusys/almalinux-bootc:10-kitten-amd64 just verify-headless   # probe one image
just verify-headless-manifest           # manifest scan only, no container needed
just verify-headless-live               # live section, needs a host that can boot systemd
```

Notes:

- The upstream `quay.io/almalinuxorg/almalinux-bootc` image is not a valid probe
  target: it ships no `openssh-server`, so the rescue-path probes fail there by design.
  Probe this fork's published image instead.
- Container probes need a CPU with x86-64-v3 support (AlmaLinux 10 glibc hard
  requirement). On older hardware `podman run` fails with
  `Fatal glibc error: CPU does not support x86-64-v3` and the whole image-probe layer
  is void — such a machine can only run `just verify-headless-manifest`. CI skips the
  image probes the same way and raises a warning.
- `just build` runs `make image`, which uses `sudo podman`, so the image lands in root's
  storage. Probing a freshly built image needs the same podman:
  `sudo env "PATH=$PATH" IMAGE=localhost/almalinux-bootc:10-kitten just verify-headless`.
- The workflow triggers on `push: main`, `workflow_dispatch` and a weekly cron — there is
  no `pull_request` trigger, so a red gate becomes visible after the merge, not before it.

## Opening a PR

1. Fork this repo (if you don't have direct push access)
2. Create a branch: `git checkout -b <topic>`
3. Make changes; commit with the prefix `feat:` / `fix:` / `docs:` / `test:` / `chore:`
4. Run the verification suite (above)
5. Open a PR against `main`
6. Wait for CI to pass

PR review is informal (solo dev + admin bypass); CI is the only gate.

## Adding a new package

If you need a package that's not in upstream `:10-kitten`:

1. Add it to `10-kitten/almalinux-10-kitten.yaml` under `packages:`
2. If it needs to be enabled/started, add a `postprocess:` script
3. Update `tests/no-gui.sh` exclusion list if your package is intentionally non-headless (and update the plan to justify)
4. Commit + PR

## Bumping the base image version

When upstream tags a new AlmaLinux release (e.g., `:10-kitten` → `:11-kitten`):

1. Add the new variant directory: `cp -r 10-kitten/ 11-kitten/`
2. Update the new YAML's `releasever:` field
3. Update `.github/workflows/build.yml` matrix to include the new variant
4. Update `README.md` "Rebase strategy" if cadence changes
5. Open a PR with `[release-bump]` prefix

## Adding a rescue tool (TPM / IPMI / etc.)

If you need an additional rescue method (per spec §6 B2):

1. Add the package to the manifest
2. Add a postprocess script that configures it (e.g., enables the systemd unit)
3. Update `tests/rescue-path.sh` to probe the new tool
4. Document the rescue procedure in `docs/RESCUE.md` (TBD)

## When in doubt, ask

Open an issue first. The fork is small; a 5-minute conversation saves a 5-hour rebase mistake.

## License

By contributing, you agree your contributions are licensed under **GPL-3.0** (the fork's inherited license). The Daedalus project uses MIT for its own code, but the fork's code MUST remain GPL-3.0.