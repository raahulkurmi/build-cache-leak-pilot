# build-cache-leak-pilot

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

## Pre-registration

The hypotheses, patterns, predicted results matrix, and counting method are committed
**before any build is run** in [docs/PREREGISTRATION.md](docs/PREREGISTRATION.md).
This is the review gate: the experiment is not executed until the pre-registration is
approved.

## Layout

```
dockerfiles/   P1..P5 — the pattern Dockerfiles (the registered design)
scripts/       00..05 — version capture, registry+builder, secret gen, build, probe, prevalence
docs/          PREREGISTRATION.md, ETHICS.md, (RESULTS.md after the run)
results/       versions.txt, markers.txt, matrix.{md,json}, prevalence.json (after the run)
summary/       one-page ChainSEC lightning-talk summary (after results)
```

## How to reproduce (run only after pre-registration is approved)

```bash
scripts/00_versions.sh          # record docker/buildx/BuildKit/gh versions
scripts/01_setup_registry.sh    # local registry:2 + buildx builder on a shared net
scripts/02_gen_secrets.sh       # generate synthetic FAKE-SECRET markers + contexts
scripts/03_build_and_push.sh    # build final + push mode=min and mode=max caches
scripts/04_probe.sh             # probe our own artifacts -> results/matrix.md
scripts/05_prevalence.sh        # GitHub code-search counts -> results/prevalence.json
```

Requires: Docker + buildx (container driver), `jq`, `openssl`, `curl`, `gh` (authed).

## Status

Pre-registration drafted. **No experiment has been run.** Awaiting review.
