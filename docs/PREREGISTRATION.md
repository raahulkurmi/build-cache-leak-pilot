# Pre-registration — Build Cache Leak Pilot

**Study:** Do secrets that multi-stage builds keep out of the *final image* still get
published through registry build caches (`--cache-to type=registry,mode=max`) or
pushed intermediate stages?

**Author:** raahulkurmi · **Date registered:** 2026-10-05
**Status:** Pre-registered. No experiment has been run at the time of writing. This
file is committed *before* any build is executed and is not edited after results are
collected (results go in `results/` and `docs/RESULTS.md`). Pre-run amendments made
before any build are logged in §10.

---

## 1. Motivation and hypothesis

Multi-stage Docker builds are the standard advice for keeping build-time secrets out
of shipped images: put the secret in an early *builder* stage, and have the final
stage `COPY --from=builder` only the compiled artifact. The final image never
contains the secret.

BuildKit can also export a **registry build cache** so later builds are fast.
`mode=max` exports the layers of **every stage, including intermediate ones**, to a
registry as cache manifests/blobs. Our hypothesis:

> **H1.** A synthetic secret placed in a builder stage is *not* recoverable from the
> final image, but *is* recoverable from a `mode=max` registry cache for the
> file/ARG/ENV/RUN patterns, because the max cache exports the builder stage's
> layers and config.
>
> **H2.** The same secret is *not* recoverable from a `mode=min` registry cache,
> because `mode=min` exports only layers that end up in the resulting (final) image.
>
> **H3 (control).** A secret supplied via `RUN --mount=type=secret` is *not*
> recoverable from the final image, the `mode=min` cache, or the `mode=max` cache,
> because secret mounts are tmpfs-mounted for a single `RUN` and never written to any
> layer or cache blob.

> **H1b (build-arg / provenance channel).** A value passed via `--build-arg` (P2b:
> `ARG LEAK_MARKER`, no `ENV`) is recorded in the SLSA provenance attestation under
> `--provenance=mode=max` and is recoverable from the **`:final` image index's
> attestation manifest**, even though the value never enters the final image config,
> any layer, or the cache export. Under `--provenance=mode=min` it is absent. This
> isolates the invocation-args channel (build-args and/or the LLB definition embedded
> in max provenance) from P2's layer/config channel.

**Two independent axes.** Cache mode (`--cache-to ...,mode=min|max`) is the axis for
P1, P2, P3, P4, P5. Provenance mode (`--provenance=mode=min|max`) is the axis for P2b.
`--cache-to` exports a cache manifest + layer blobs only: no attestations, no per-stage
image config. Provenance is pinned to `mode=min` for every build except P2b's leak
build, so the two axes never mix.

If H1 holds, "multi-stage keeps it out of the image" is a false sense of safety
whenever a `mode=max` cache is pushed to a registry others can pull.

---

## 2. Secrets are synthetic (ethics)

Every "secret" is a fake token **generated locally for this study**, matching no real
service. Canonical form:

```
FAKE-SECRET-<PATTERN>-<RANDOMHEX>-DO-NOT-USE
```

e.g. `FAKE-SECRET-P1-9f3a2c71b4e8-DO-NOT-USE`. These strings are the **detection
markers** we grep for. No real credential, `.npmrc` token, cloud key, or third-party
material is ever used. See `docs/ETHICS.md`.

---

## 3. Patterns under test (independent variable)

Each pattern is one Dockerfile. All share the same shape: a **builder** stage that
receives the fake secret one way, builds a trivial artifact (`/app/out.txt`), and a
**final** stage `FROM` a clean base that does `COPY --from=builder /app/out.txt` only.
The final stage never references the secret.

| ID  | Pattern | How the fake secret enters the builder | Pre-registered expectation |
|-----|---------|----------------------------------------|----------------------------|
| P1  | `COPY .npmrc` | A file (`.npmrc` containing the token) is `COPY`'d into the builder | Leaks in max cache |
| P2  | `ARG`/`ENV` | `ARG SECRET` passed via `--build-arg` (to P2 only), promoted to `ENV SECRET` in builder | Leaks in max cache (image config of builder stage) |
| P2b | `ARG` only | `ARG LEAK_MARKER` passed via `--build-arg` (to P2b only), consumed by a `RUN`, never written to a layer, no `ENV` | Leaks **only** in the provenance attestation under `--provenance=mode=max` (H1b) |
| P3  | `RUN echo` | Literal marker baked into `RUN echo "<marker>" > /tmp/secret.txt` (substituted into the per-run context copy; no build-arg) | Leaks in max cache (layer diff) |
| P4  | `--mount=type=secret` **(control)** | `RUN --mount=type=secret,id=tok cat /run/secrets/tok`; receives **zero** build-args | **Does not leak** anywhere |

Supplementary (clearly labelled as extras, same expectation logic):

| ID  | Pattern | Note |
|-----|---------|------|
| P5  | `COPY` then `RUN rm` in a later layer | Deleting the file in a later layer does **not** remove it from the earlier layer's blob; expected to leak in max cache. Demonstrates layer history. |

Each pattern's build context contains only the input for its own channel (`.npmrc`
for P1/P5, `secret.tok` for P4). Build-args are per-pattern: `SECRET` goes to P2
only and `LEAK_MARKER` to P2b only. No build-arg is shared across patterns.

The **dependent variable** is a recoverability verdict (`RECOVERABLE` /
`NOT_RECOVERABLE`) for each pattern in each location of §4.

---

## 4. Locations probed (dependent variable)

For every pattern we probe these published artifacts in a registry we own (a local
`registry:2` container, `localhost:5000`):

1. **Final image config:** config blob of `localhost:5000/pilot/<PID>:final`
2. **Final image layers:** layer blobs of `:final`
3. **`mode=min` registry cache:** `:cache-min`
4. **`mode=max` registry cache:** `:cache-max`
5. **Provenance attestation (max):** attestation manifest in the `:final` index.
   P2b only (`:final` is built with `--provenance=mode=max`); n/a for other patterns.
6. **Provenance attestation (min):** for P2b, the attestation in the
   `:final-provmin` index (same inputs, `--provenance=mode=min`); for every other
   pattern, the attestation in the `:final` index (pinned `mode=min`).

"Recoverable" = the exact `FAKE-SECRET-<PID>-...` marker for that pattern is found by
our probe. Probing is done **only against artifacts we produced in our own
registry** — see §6.

### Probe method (`scripts/04_probe.sh`)
- **Recursive walk:** fetch the tag via `/v2/<repo>/manifests/<ref>`. An index's
  children are fetched via `/manifests/<digest>` and classified: a child annotated
  `vnd.docker.reference.type=attestation-manifest` is an **attestation** (all its
  blobs → location 5/6); any other child is an **image manifest** (config → location
  1, layers → location 2). Blobs are fetched via `/blobs/<digest>`.
- **Cache tags:** every descriptor in the cache export is fetched; the
  `application/vnd.buildkit.cacheconfig.v0` blob is parsed and every blob it
  references (`.layers[].blob`) is fetched too.
- **Matching is path-agnostic:** each blob is grepped raw, then as its
  gzip-decoded (or zstd-decoded) stream (which covers tar file contents and headers),
  then as a base64 DSSE `.payload` if present. We do **not** bind to a SLSA JSON
  path, because the key layout differs between BuildKit versions.
- **Fail-loud verdicts:** a ref or blob that can't be fetched gives `PROBE_ERROR`,
  and a location with no blobs of that class (e.g. no attestation attached) gives
  `ABSENT`. Neither is ever reported as `NOT_RECOVERABLE`.

A pattern is `RECOVERABLE` in a location iff the marker appears in any blob of that
location's class.

---

## 5. Pre-registered results matrix (predictions)

Filled in **before** running. `RESULTS.md` will place the observed matrix beside it.

| Pattern | Final config | Final layers | `mode=min` cache | `mode=max` cache | Prov-attest (max) | Prov-attest (min) |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|
| P1 COPY .npmrc         | NOT | NOT | NOT | **RECOVERABLE** | n/a | NOT |
| P2 ARG/ENV             | NOT | NOT | NOT | **RECOVERABLE** | n/a | NOT |
| P2b ARG only           | NOT | NOT | NOT | NOT | **RECOVERABLE** | NOT |
| P3 RUN echo            | NOT | NOT | NOT | **RECOVERABLE** | n/a | NOT |
| P4 secret mount (ctrl) | NOT | NOT | NOT | **NOT** | n/a | NOT |
| P5 COPY then rm        | NOT | NOT | NOT | **RECOVERABLE** | n/a | NOT |

(The f7310b3 "Final image" column is split into config and layers. Cells carried over
from f7310b3 are unchanged.)

Primary success criterion: **P4 must be NOT-recoverable in every probed column** (the
control validates the method), and at least one of P1–P3 must be RECOVERABLE in the
`mode=max` cache column (demonstrates the leak). H1b is supported iff P2b is
RECOVERABLE in Prov-attest (max), NOT in Prov-attest (min), and NOT in all four
image/cache columns. A `PROBE_ERROR` or `ABSENT` in any predicted cell is reported as
a failed measurement, not as NOT. A deviation from any other cell is reported and
discussed, not hidden.

---

## 6. Ethics constraints (hard, binding)

- **No third-party content.** We never download, scan, or store any cache layer or
  image content that we did not produce. All probing is against artifacts this study
  pushed to our own `localhost:5000`.
- **Synthetic secrets only.** Fake, locally generated markers; never a real
  credential.
- **No AWS.** No cloud provider is used for any part of the study.
- **GitHub: metadata only, within rate limits.** Part 2 uses GitHub code search for
  **counts only** (`total_count`). We do not fetch, store, or publish file contents or
  repository names. Queries are throttled under the authenticated code-search limit
  (~10 requests/min) with sleeps between calls.

---

## 7. Part 2 — prevalence (pre-registered counting method)

Metadata-only. We query GitHub **code search** and record only `total_count` for each
query, plus the date and the exact query string. No repository names, file contents,
or owners are stored or reported.

Pre-registered queries (restricted to workflow files; exact strings recorded in
`results/prevalence.json`):

- **Q1 — `mode=max` registry cache-to:**
  `"cache-to" "type=registry" "mode=max" path:.github/workflows`
- **Q2 — any registry cache-to (denominator):**
  `"cache-to" "type=registry" path:.github/workflows`
- **Q3 — GHA cache (comparison denominator):**
  `"cache-to" "type=gha" path:.github/workflows`
- **Q4 — pushing a specific build target (intermediate-stage push signal):**
  `"target:" "push: true" path:.github/workflows` (buildx action with a non-final
  `target`), cross-checked against `"--target" "--push" path:.github/workflows`.

Reported outcomes: the raw `total_count` per query, Q1/Q2 as a ratio, and Q4 as an
upper-bound signal (acknowledged as noisy — see limitations). GitHub code search
counts are **approximate and non-exhaustive**; they bound prevalence, they do not
measure it exactly. Sample definition = "public files indexed by GitHub code search
on the query date." The query date and the running `gh` version are recorded.

---

## 8. Environment to be recorded

`scripts/00_versions.sh` writes `results/versions.txt`: bash version (the run host
needs bash ≥ 5; `scripts/lib.sh` refuses to run otherwise), `docker version`,
`docker buildx version`, BuildKit version (from the builder node and the
`registry:2`/moby buildkit image digest), `gh --version`, host OS. Captured at run
time, not now.

## 9. Deviations policy

Any departure from this plan (added pattern, changed probe, failed control) is logged
in `docs/RESULTS.md` under "Deviations from pre-registration" with the reason. This
file is not rewritten.

## 10. Pre-run amendments (before any build; no experiment has been run)

Made after f7310b3 and before the remote anchor. These are harness corrections plus
one registered addition. No data existed when they were made.

1. **P2b added + H1b registered.** Prediction is tied to the real mechanism: provenance
   attestation on the `:final` index, not the cache export. Provenance mode is a
   separate axis from cache mode (§1, §4).
2. **Probe recursion fixed.** The f7310b3 probe read only top-level digests and fetched
   child *manifests* via `/blobs/`, which `registry:2` does not serve. Fetch failures
   were silently skipped, so the "Final image" column would have been a false
   NOT. It now walks index → manifests, classifies attestations, descends cacheconfig,
   and reports `PROBE_ERROR` instead of skipping (§4).
3. **P4 control decontaminated.** f7310b3 passed `--build-arg SECRET=<marker>` to
   every pattern, P4 included. Build-args are now per-pattern and P4 gets none. P3,
   which depended on that shared arg, now bakes its marker as a literal in `RUN echo`.
4. **Provenance pinned.** `--provenance=mode=min` is explicit on every build except
   P2b's leak build (`mode=max`), instead of relying on the buildx default.
5. **bash ≥ 5 required** and enforced in `scripts/lib.sh` (macOS `/bin/bash` is 3.2).
