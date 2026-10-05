# Results — Build Cache Leak Pilot

Registered design: `prereg-v1` (51d2c55) (git: prereg-v1, 51d2c55). Raw results: 0092d63
(git: 0092d63). Source tags point to
`results/matrix.json`, `results/prevalence.json`, `results/versions.txt`,
`docs/RELATED.md`, and, for predicted values and pattern design only,
`docs/PREREGISTRATION.md` at `prereg-v1`. A sentence without a tag is labelled
**Interpretation:** or **Process note:**. Git-verifiable facts use (git: <ref> —
verifiable via git log / tag timestamps). Cell counts (36, 31, 28, 3) are computed here by
comparing matrix.json with the predictions in PREREGISTRATION.md §5.

---

## 1. Scorecard

> **DRAFT. Rahul and the reviewer finalise the wording.**

Of 31 pre-registered cells, 28 matched and 3 missed (computed here: matrix.json, all
patterns/all locations, against PREREGISTRATION.md §5). One miss is primary: P2 · max cache was predicted
RECOVERABLE in the registration (PREREGISTRATION.md §5 at `prereg-v1`) and measured
NOT_RECOVERABLE (matrix.json: P2/cache_max). Process note: the mechanism was questioned
during the pre-run review, but that doubt was NOT entered into the registration. We note
it here only to be transparent that the miss was discussed beforehand; it was not
foreseen on the record (process fact; not recorded in the result files). The other two are low-confidence provenance cells, P2 ·
attest-min and P2b · attest-min. Both were predicted RECOVERABLE † and measured
NOT_RECOVERABLE (matrix.json: P2/attest_provmin, P2b/attest_provmin;
PREREGISTRATION.md §5). The registration de-gated those two cells before the run, so
they are reported measurements, not success criteria (PREREGISTRATION.md §5, §10
item 6; git: 51d2c55, 0092d63). Their miss is itself a measured version fact: at BuildKit v0.33.1, the
build-arg marker could not be recovered from the min-mode provenance attestation in our
setup (matrix.json: P2/attest_provmin, P2b/attest_provmin; versions.txt).

The 28 matched cells:

- P1, P3 and P5 were RECOVERABLE from the `mode=max` registry cache (matrix.json:
  P1/cache_max, P3/cache_max, P5/cache_max).
- The P4 `--mount=type=secret` control was NOT_RECOVERABLE in all five locations probed
  for it, with the attest-min cell measured at BuildKit v0.33.1 (versions.txt; matrix.json: P4/final_config, P4/final_layers, P4/cache_min, P4/cache_max,
  P4/attest_provmin). P4 · attest-max was not built (matrix.json: P4/attest_provmax =
  n/a).
- P2b was RECOVERABLE from the provenance attestation under `--provenance=mode=max` at
  BuildKit v0.33.1 (matrix.json: P2b/attest_provmax; versions.txt).
- All other final-config, final-layers and `mode=min` cache cells were NOT_RECOVERABLE
  as predicted (matrix.json: P1–P5, P2b/final_config, final_layers, cache_min).

Status of the registered success criteria (PREREGISTRATION.md §5):

| Criterion | Measured | Source |
|---|---|---|
| P4 NOT_RECOVERABLE in every probed column | Met: 5/5 probed columns NOT_RECOVERABLE | matrix.json: P4/* |
| At least one of P1–P3 RECOVERABLE in `mode=max` cache | Met: P1 and P3 RECOVERABLE | matrix.json: P1/cache_max, P3/cache_max |
| H1b: P2b RECOVERABLE in attest-max AND NOT_RECOVERABLE in final config, final layers, min cache, max cache | Met at BuildKit v0.33.1 | matrix.json: P2b/*; versions.txt |
| No PROBE_ERROR / ABSENT in any predicted cell | Met: 0 PROBE_ERROR, 0 ABSENT | matrix.json: all cells |

Measured vs predicted, all 36 cells: 6 patterns × 6 locations in matrix.json, of which 5
are n/a. A cell marked ✗ is a miss.

| Pattern | Final config | Final layers | `mode=min` cache | `mode=max` cache | Prov-attest (max) | Prov-attest (min) |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| P1 COPY .npmrc | NOT | NOT | NOT | **REC** | n/a | NOT |
| P2 ARG/ENV | NOT | NOT | NOT | NOT ✗ (pred REC) | n/a | NOT ✗ (pred REC †) |
| P2b ARG only | NOT | NOT | NOT | NOT | **REC** | NOT ✗ (pred REC †) |
| P3 RUN echo | NOT | NOT | NOT | **REC** | n/a | NOT |
| P4 secret mount (ctrl) | NOT | NOT | NOT | NOT | n/a | NOT |
| P5 COPY then rm | NOT | NOT | NOT | **REC** | n/a | NOT |

Measured values come from matrix.json; predictions come from PREREGISTRATION.md §5 at
`prereg-v1`. NOT = NOT_RECOVERABLE, REC = RECOVERABLE. † marks the low-confidence cells
that were de-gated in §10 item 6.

Interpretation: the P4 result supports the probe method in our setup. A control that
stays NOT_RECOVERABLE in every probed location means the probe isn't flagging a marker
just because it was passed into the build.

---

## 2. Where the marker was and was not recovered

All statements in this section describe our setup: one host, a local `registry:2`, and
synthetic markers (versions.txt; PREREGISTRATION.md §2). Provenance cells are measured at
BuildKit v0.33.1 (versions.txt). The probe reports one verdict per location. It does not
record which blob inside a location held the marker (PREREGISTRATION.md §4).

**Files created in a builder stage (P1, P3, P5).**
- The P1 marker, inside a `COPY`'d `.npmrc` (PREREGISTRATION.md §3), was recovered from
  the `mode=max` registry cache (matrix.json: P1/cache_max).
- The P3 marker, written to a file by `RUN echo` (PREREGISTRATION.md §3), was recovered
  from the `mode=max` registry cache (matrix.json: P3/cache_max).
- The P5 marker was `COPY`'d in and then deleted by `RUN rm` in a later instruction
  (PREREGISTRATION.md §3). It
  was still recovered from the `mode=max` registry cache (matrix.json: P5/cache_max), so
  in our setup the later `rm` did not remove it from that cache export.
- None of the three markers was recovered from the final image config, the final image
  layers, the `mode=min` cache, or the min-mode provenance attestation at BuildKit
  v0.33.1 (matrix.json: P1, P3, P5 / final_config, final_layers, cache_min,
  attest_provmin; versions.txt).

**Builder-stage ENV with no file written (P2).**
- The P2 marker was passed as `ARG SECRET` and promoted to `ENV` in the builder stage
  (PREREGISTRATION.md §3). It
  was not recovered from any of the five locations probed: final config, final layers,
  `mode=min` cache, `mode=max` cache, and the min-mode provenance attestation at
  BuildKit v0.33.1 (matrix.json: P2/final_config, P2/final_layers, P2/cache_min,
  P2/cache_max, P2/attest_provmin; versions.txt).
- Our only finding is that it was not present in the probed image, cache or attestation
  artifacts in our setup (matrix.json: P2 row). We make no claim about why.

**Build-arg only (P2b).**
- At BuildKit v0.33.1, the P2b marker was recovered from the provenance attestation on
  the `:final` index built with `--provenance=mode=max` (PREREGISTRATION.md §3, §4;
  matrix.json: P2b/attest_provmax; versions.txt). P2b's marker entered only as a build-arg,
  `ARG LEAK_MARKER`, with no `ENV` (PREREGISTRATION.md §3).
- It was not recovered from the final image config, the final image layers, the
  `mode=min` cache or the `mode=max` cache (matrix.json: P2b/final_config,
  P2b/final_layers, P2b/cache_min, P2b/cache_max).
- At BuildKit v0.33.1, it was not recovered from the provenance attestation on the
  `:final-provmin` index built with `--provenance=mode=min` (PREREGISTRATION.md §4;
  matrix.json: P2b/attest_provmin; versions.txt).

**Control: secret mount (P4).**
- The P4 marker was supplied only through `--mount=type=secret` (PREREGISTRATION.md §3)
  and was not recovered
  from any of the five locations probed, with attest-min at BuildKit v0.33.1 (matrix.json:
  P4/final_config, P4/final_layers, P4/cache_min, P4/cache_max, P4/attest_provmin;
  versions.txt). P4 · attest-max was not built
  (matrix.json: P4/attest_provmax = n/a).

| Channel (how the marker entered, per PREREGISTRATION.md §3) | Recovered from | Not recovered from | Source |
|---|---|---|---|
| File in builder stage (P1, P3, P5) | `mode=max` cache | final config, final layers, `mode=min` cache, attest-min (at v0.33.1) | matrix.json: P1, P3, P5 rows; versions.txt |
| Builder ENV, no file (P2) | — | all 5 probed (attest-min at v0.33.1) | matrix.json: P2 row; versions.txt |
| Build-arg only (P2b) | attest-max, at BuildKit v0.33.1 | final config, final layers, both caches, attest-min (at v0.33.1) | matrix.json: P2b row; versions.txt |
| Secret mount (P4, control) | — | all 5 probed (attest-min at v0.33.1) | matrix.json: P4 row; versions.txt |

Interpretation: in our setup the cells split by channel rather than by "caches leak" in
general. Markers that landed in a builder-stage file were recoverable from the
`mode=max` cache only. A marker that existed only as builder-stage ENV was not found in
any image or cache artifact. A marker passed only as a build-arg was found only in the
max-mode provenance attestation (at BuildKit v0.33.1). The secret-mount control was not
found anywhere we looked.

---

## 3. Prevalence (GitHub code-search counts)

**These counts bound how many public files match each query string. They do not measure
secret exposure, exploited instances, or even confirmed use of the pattern. A
query-string match is not a confirmed leaking configuration** (PREREGISTRATION.md §7).
The unit is
"public files indexed by GitHub code search on the query date". Counts are approximate
and non-exhaustive (PREREGISTRATION.md §7). Only `total_count` was recorded. No
repository names, owners or file contents were fetched (PREREGISTRATION.md §6, §7).

Q1–Q4 were queried at 2026-10-05T16:45:54Z and Q4b at 2026-10-05T16:51:20Z, all with
gh version 2.101.0 (2026-09-15) (prevalence.json: queried_at, gh,
q4b_target_push_workflows.queried_at, q4b_target_push_workflows.gh). All five queries are
limited to `path:.github/workflows` (prevalence.json: query fields).

**Intermediate-target push signal (Q4b, Q4).**
- Q4b, `"--target" "--push" path:.github/workflows`, matched 1020 files
  (prevalence.json: q4b_target_push_workflows). It is the §7 cross-check. The frozen
  `scripts/05` omitted it, so it was run separately with the same method, about five
  minutes after Q1–Q4 (prevalence.json: q4b_target_push_workflows.note,
  q4b_target_push_workflows.queried_at).
- Q4, `"target:" "push: true" path:.github/workflows`, matched 21952 files. It is
  annotated `upper_bound: true`, because it matches any workflow file containing both
  strings, not only files that push a non-final target (prevalence.json: q4_target_push).
- Q4 and Q4b match different string forms (YAML keys vs CLI flags) under the same path
  filter (prevalence.json: q4_target_push.query, q4b_target_push_workflows.query). We
  report both and do not combine them or choose between them.

**Registry cache-to (Q1, Q2) and GHA cache (Q3).**
- Q1, `"cache-to" "type=registry" "mode=max" path:.github/workflows`, matched 15008
  files (prevalence.json: q1_max_registry_cache).
- Q2, `"cache-to" "type=registry" path:.github/workflows`, matched 18976 files
  (prevalence.json: q2_any_registry_cache).
- The Q1/Q2 ratio registered in PREREGISTRATION.md §7, computed here as 15008 / 18976 ≈
  0.7909, is a ratio of two approximate string-match counts and means nothing beyond that
  (prevalence.json: q1_max_registry_cache, q2_any_registry_cache).
- Q3, `"cache-to" "type=gha" path:.github/workflows`, matched 171520 files
  (prevalence.json: q3_gha_cache).

| Query | String (all `path:.github/workflows`) | total_count | Note | Source |
|---|---|--:|---|---|
| Q4b | `"--target" "--push"` | 1020 | §7 cross-check, queried 16:51:20Z | prevalence.json: q4b_target_push_workflows |
| Q4 | `"target:" "push: true"` | 21952 | **upper bound** (`upper_bound: true`) | prevalence.json: q4_target_push |
| Q1 | `"cache-to" "type=registry" "mode=max"` | 15008 | | prevalence.json: q1_max_registry_cache |
| Q2 | `"cache-to" "type=registry"` | 18976 | Q1/Q2 ≈ 0.7909 | prevalence.json: q2_any_registry_cache |
| Q3 | `"cache-to" "type=gha"` | 171520 | comparison denominator | prevalence.json: q3_gha_cache |

Interpretation: a match shows that the string appears in a public workflow file. It does
not show whether the cache or image is pushed to a registry other people can pull from,
whether a secret goes through a builder-stage file, or whether anything is recoverable.
Our Part 1 cells cannot be projected onto these counts.

---

## 4. Contribution

> **FENCED: DRAFT FOR SIGN-OFF.** Rahul and the reviewer finalise this wording. Do not
> quote it or reuse it before sign-off.

**What is already known.** The risk this pilot measures is widely known and documented.
Secrets in published container images have been measured at scale (RELATED.md:
§1, Dahlmanns et al. ASIA CCS 2023, arXiv 2307.03958; Kapelinski et al. arXiv 2608.02669).
We grepped the full text of the arXiv HTML rendering of Dahlmanns et al.
- "BuildKit", "multi-stage", "attestation" and "provenance" each occur 0 times.
- All 5 occurrences of "cache" refer to browser caches inside images.
(RELATED.md: §1). Docker's documentation states that `mode=max` provenance exposes
build-arg values, and that `mode=min` does not (RELATED.md: §2). A 2023 blog post shows a
single uncontrolled example of recovering a build-arg (RELATED.md: §2, Kothari). The
claim that `mode=max` registry caches leak secrets appears in documentation and blog
posts as a warning, without a measurement, in the sources we found (RELATED.md: §3). This
pilot does not report a new leak class or a new attack.

**What this pilot adds.** Within those limits, the contribution is narrow.

1. **A pre-registered, controlled measurement.** The hypotheses, the patterns and the
   full predicted matrix are in the registration commit (prereg-v1 / 51d2c55), which
   precedes the earliest commit containing any build output (0092d63) in the repository
   history (PREREGISTRATION.md §5, §10; git: prereg-v1, 0092d63). Recoverability was then measured across
   the final image, the `mode=min` and `mode=max` registry cache exports, and the
   min-mode and max-mode provenance attestations. A `--mount=type=secret` control (P4)
   was NOT_RECOVERABLE in all five locations probed for it, with attest-min at BuildKit
   v0.33.1 (matrix.json: P4 row; versions.txt).
   Misses are reported against the registration rather than corrected: 28 of 31 cells
   matched and 3 missed (computed here: matrix.json against PREREGISTRATION.md §5).
2. **A breakdown by channel**, in our setup:
   - marker in a builder-stage file → recoverable from the `mode=max` cache (matrix.json:
     P1/cache_max, P3/cache_max, P5/cache_max);
   - marker held only as builder-stage `ENV` → not recovered from any probed image,
     cache or attestation location, with attestation at BuildKit v0.33.1 (matrix.json:
     P2 row; versions.txt);
   - marker passed only as a build-arg → recoverable from the provenance attestation
     under `mode=max`, and not from min-mode provenance, at BuildKit v0.33.1 (matrix.json:
     P2b/attest_provmax, P2b/attest_provmin; versions.txt).

For the build-arg channel, our result is a controlled, version-pinned confirmation of a
behaviour that is documented but, in the sources we found, unmeasured (RELATED.md: §2;
matrix.json: P2b row; versions.txt). It is not new.

**How far we searched.** We found no published measurement of secret recoverability
from registry build-cache exports. Our search was not systematic: about 10 web queries,
with no full-database search of ACM DL, IEEE Xplore or USENIX (RELATED.md: header, §3).
"We found none" is the strongest claim this supports. It does not show that none exists.

---

## 5. Limitations

The holes we know about, roughly in order of how much they limit the results.

1. **One BuildKit version.** Every provenance result was measured at BuildKit v0.33.1
   only (versions.txt). That covers P2b RECOVERABLE in attest-max and P2/P2b
   NOT_RECOVERABLE in attest-min (matrix.json: P2b/attest_provmax, P2b/attest_provmin,
   P2/attest_provmin). Another BuildKit version may record build-args differently and
   may give different cells.
2. **One host.** All builds and probes ran on one macOS machine with Docker Desktop
   4.43.2, engine 28.3.2, and buildx v0.25.0-desktop.1 (versions.txt). We did not test
   Linux hosts, other builder drivers or CI runners.
3. **One run of the experiment.** Scripts 03 and 04 were executed once, giving one verdict
   per cell (matrix.json; versions.txt: single capture at 2026-10-05T16:45:07Z). The run
   was not repeated, so run-to-run variation is unmeasured.
4. **Local registry, synthetic markers.** Artifacts were pushed to a local `registry:2`
   (versions.txt: registry image digest), not to a cloud or production registry, whose
   storage or manifest handling may differ. The secrets were synthetic
   `FAKE-SECRET-…-DO-NOT-USE` markers, not real credentials (PREREGISTRATION.md §2).
5. **A NOT verdict is bounded by what the probe can decode.** The probe matches the exact
   marker in raw blob bytes, gzip- or zstd-decoded streams, and base64 DSSE payloads
   (PREREGISTRATION.md §4). A marker stored in any other encoding would read as
   NOT_RECOVERABLE. This applies to every NOT cell, including the P2 cells.
6. **No blob-level attribution.** The probe gives one verdict per location and does not
   record which blob inside the location held the marker (PREREGISTRATION.md §4).
   Statements such as "P5's marker was recoverable after `rm`" are about the location
   (matrix.json: P5/cache_max), not about a specific layer.
7. **Three of 31 predicted cells missed.** They are reported against the registration
   and not corrected (Section 1; matrix.json: P2/cache_max, P2/attest_provmin,
   P2b/attest_provmin).
8. **The design was amended before the run.** Between the initial registration commit
   (73695c2) and `prereg-v1`, the probe, the build-args, the provenance pinning and the P2b
   predictions were changed. All of this happened before any build (git: prereg-v1, 0092d63),
   and it is logged in
   PREREGISTRATION.md §10 (git: 73695c2). A reader should judge the predictions at
   `prereg-v1`, not at 73695c2.
9. **Prevalence counts are file matches only.** Part 2 recorded GitHub code-search
   `total_count`, which counts indexed files and is approximate. No contents or names
   were fetched, and no third-party image or cache was accessed (PREREGISTRATION.md §6,
   §7; prevalence.json). The counts bound string matches. They do not measure use,
   exposure or recoverability (Section 3). Each query ran once, and Q4b ran about five
   minutes after Q1–Q4 (prevalence.json: queried_at, q4b_target_push_workflows.queried_at),
   so the counts are a snapshot.
10. **The prior-work search was not systematic.** It used about 10 web queries, with no
    full-database search (RELATED.md: header). "We found no measurement" (Section 4) is
    limited by that.
11. **One citation check is not closed.** Our reading of Dahlmanns et al.'s scope comes
    from the full text of the arXiv HTML rendering. The ACM camera-ready returned 403 and
    was not read (RELATED.md: §1).
12. Process note: **One operator, no independent replication.** One person ran the
    experiment and wrote the probe, and nobody else has re-run it (process fact; not
    recorded in the result files). The scripts and the registered design are in
    the repository at `prereg-v1` so that someone else can (git: prereg-v1).
