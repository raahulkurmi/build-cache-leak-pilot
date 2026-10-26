# build-cache-leak-pilot

## TL;DR

- **Question.** Do secrets that a multi-stage Docker build keeps out of the final image still get published through a `mode=max` registry build cache or a provenance attestation?
- **What was done.** Six Dockerfile patterns each put a synthetic secret into a builder stage a different way; each was built once at BuildKit v0.33.1, pushed to a local registry, and probed in six locations ([docs/RESULTS.md](docs/RESULTS.md) §1).
- **Headline.** A secret used only in a builder stage did not appear in the final image, but when it was written to a file there (P1, P3, P5) it was published in the `mode=max` build cache ([results/matrix.md](results/matrix.md)). 28 of 31 pre-registered predictions held and 3 missed, one of them primary (P2 · `mode=max` cache).
- **What it does not show.** One BuildKit version, one host, one run, a local registry and synthetic markers. It measures no real leak, and the GitHub code-search counts are string matches, not exposure ([Limitations](docs/RESULTS.md#5-limitations)).
- **Pre-registration.** [docs/PREREGISTRATION.md](docs/PREREGISTRATION.md) at `prereg-v1` (`65b225e`). That tree was the head of `main` on GitHub at 2026-10-05T15:54:58Z, before the first results push ([docs/TIMING_EVIDENCE.md](docs/TIMING_EVIDENCE.md), which also covers the history rewrites).

A small, pre-registered pilot study: **do secrets that multi-stage Docker builds keep
out of the final image still get published through registry build caches
(`--cache-to type=registry,mode=max`) or pushed intermediate stages?**

> ⚠️ All "secrets" here are **synthetic** markers (`FAKE-SECRET-…-DO-NOT-USE`).
> Nothing in this repo uses, needs, or stores a real credential. See
> [docs/ETHICS.md](docs/ETHICS.md).

## What this is

- **Part 1 — controlled experiment.** Build five multi-stage Dockerfiles that each
  place a fake secret in a *builder* stage a different way, push the final image plus a
  `mode=min` and a `mode=max` registry cache to a **local registry we own**, then check
  whether the fake marker is recoverable from each. `--mount=type=secret` is the safe
  **control** and must be non-recoverable everywhere.
- **Part 2 — prevalence (metadata only).** Count public GitHub workflows that use
  `cache-to type=registry` with `mode=max`, and those that push intermediate stages.
  Counts only — no repository names.

## Results

Results, including which predictions missed, are in [docs/RESULTS.md](docs/RESULTS.md).
Read them with the [Limitations](docs/RESULTS.md#5-limitations) section: one BuildKit
version, one host, one run, and a local registry.

## Pre-registration and history

The hypotheses, patterns, predicted results matrix and counting method are in
[docs/PREREGISTRATION.md](docs/PREREGISTRATION.md).

- The registered predictions were committed in `65b225e` (`prereg-v1`), before the
  results commit `1da575f`.
- Commit dates are set by the author, so commit order alone is not independent
  evidence of timing.
- The history was rewritten twice, both times preserving author and committer dates and
  commit order:
  - on 2026-10-05, to remove AI co-author trailers from commit messages;
  - on 2026-10-17, to replace a work email address and remove a hardware (MAC) address
    from a hostname in `results/versions.txt`.

  [docs/COMMIT_MAP.md](docs/COMMIT_MAP.md) maps old SHAs to new ones.
- The `prereg-v1` tag was recreated after the run. It points to the registered
  design but is not timing evidence.
- GitHub's server-side push records are in
  [docs/TIMING_EVIDENCE.md](docs/TIMING_EVIDENCE.md).

## Layout

```
dockerfiles/   P1..P5 + P2b — the pattern Dockerfiles (the registered design)
scripts/       00..05 — version capture, registry+builder, secret gen, build, probe, prevalence
docs/          PREREGISTRATION.md, ETHICS.md, RESULTS.md, RELATED.md, TIMING_EVIDENCE.md, COMMIT_MAP.md
results/       versions.txt, matrix.{md,json}, verdicts.{csv,json}, prevalence.json
```

## How to reproduce

```bash
bash --version                  # MUST be >= 5 before running anything (see below)
scripts/00_versions.sh          # record docker/buildx/BuildKit/gh versions
scripts/01_setup_registry.sh    # local registry:2 + buildx builder on a shared net
scripts/02_gen_secrets.sh       # generate synthetic FAKE-SECRET markers + contexts
scripts/03_build_and_push.sh    # build final + push mode=min and mode=max caches
scripts/04_probe.sh             # probe our own artifacts -> results/matrix.md
scripts/05_prevalence.sh        # GitHub code-search counts -> results/prevalence.json
```

Requires: **bash ≥ 5**, Docker + buildx (container driver), `jq`, `openssl`, `curl`, `gzip`,
`gh` (authed).

macOS ships `/bin/bash` 3.2, and these scripts use `declare -A`, `${var,,}` and empty
arrays under `set -u`. Run `brew install bash` and check that `bash --version` (the
`#!/usr/bin/env bash` shebang resolves through `PATH`) reports 5.x **before step 00**.
`scripts/lib.sh` exits early under an older bash.

## Status

The experiment has been run once, at BuildKit v0.33.1. Results are in
[docs/RESULTS.md](docs/RESULTS.md).

## How this fits

This pilot is one of several studying one question: when a security check passes, what has
it actually established? The question started from a threshold-signing project,
[threshold-signing-k8s](https://github.com/raahulkurmi/threshold-signing-k8s). Here the check
that passes is inspection of the final image: its config and layers held no marker for any
pattern, yet the `mode=max` cache pushed alongside it held the P1, P3 and P5 markers, in this
pilot's setup.

## License

Code (`scripts/`, `dockerfiles/`) is under the [MIT License](LICENSE). Documentation
and results (`docs/`, `results/`, this README) are under
[CC BY 4.0](LICENSE-CC-BY-4.0).
