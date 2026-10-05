# Pre-registration — Build Cache Leak Pilot

**Study:** Do secrets that multi-stage builds keep out of the *final image* still get
published through registry build caches (`--cache-to type=registry,mode=max`) or
pushed intermediate stages?

**Author:** raahulkurmi · **Date registered:** 2026-10-05
**Status:** Pre-registered. No experiment has been run at the time of writing. This
file is committed *before* any build is executed and is not edited after results are
collected (results go in `results/` and `docs/RESULTS.md`).

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
| P2  | `ARG`/`ENV` | `ARG SECRET` passed via `--build-arg`, promoted to `ENV SECRET` in builder | Leaks in max cache (image config of builder stage) |
| P3  | `RUN echo` | `RUN echo "$token" > /tmp/secret` in the builder | Leaks in max cache (layer diff) |
| P4  | `--mount=type=secret` **(control)** | `RUN --mount=type=secret,id=tok cat /run/secrets/tok` | **Does not leak** anywhere |

Supplementary (clearly labelled as extras, same expectation logic):

| ID  | Pattern | Note |
|-----|---------|------|
| P5  | `COPY` then `RUN rm` in a later layer | Deleting the file in a later layer does **not** remove it from the earlier layer's blob; expected to leak in max cache. Demonstrates layer history. |

The **dependent variable** is a three-way recoverability verdict
(`RECOVERABLE` / `NOT_RECOVERABLE`) for each pattern in each of three locations.

---

## 4. Locations probed (dependent variable)

For every pattern we build once and probe three published artifacts in a registry we
own (a local `registry:2` container, `localhost:5000`):

1. **Final image** — `localhost:5000/pilot/<PID>:final`
2. **`mode=min` registry cache** — `localhost:5000/pilot/<PID>:cache-min`
3. **`mode=max` registry cache** — `localhost:5000/pilot/<PID>:cache-max`

"Recoverable" = the exact `FAKE-SECRET-<PID>-...` marker for that pattern is found by
our probe. Probing is done **only against artifacts we produced in our own
registry** — see §6.

### Probe method
- **Image config + history:** pull the manifest/config JSON via the registry v2 API
  and `docker buildx imagetools inspect --raw`; grep config `Env`, `history` entries.
- **Layer blobs:** for each blob referenced by a manifest **we pushed**, download from
  our own `localhost:5000`, decompress, `tar`-list, and grep file contents for the
  marker.
- **Cache manifests:** `mode=min`/`mode=max` caches are pushed as their own tags; we
  enumerate the referenced blobs and grep them the same way.

A pattern is `RECOVERABLE` in a location iff the marker appears in any blob/config/
history of the artifact(s) at that location.

---

## 5. Pre-registered results matrix (predictions)

Filled in **before** running. `RESULTS.md` will place the observed matrix beside it.

| Pattern | Final image | `mode=min` cache | `mode=max` cache |
|---------|:-----------:|:----------------:|:----------------:|
| P1 COPY .npmrc        | NOT | NOT | **RECOVERABLE** |
| P2 ARG/ENV            | NOT | NOT | **RECOVERABLE** |
| P3 RUN echo           | NOT | NOT | **RECOVERABLE** |
| P4 secret mount (ctrl)| NOT | NOT | **NOT** |
| P5 COPY then rm       | NOT | NOT | **RECOVERABLE** |

Primary success criterion: **P4 must be NOT-recoverable in all three columns** (the
control validates the method), and at least one of P1–P3 must be RECOVERABLE in the
`mode=max` column (demonstrates the leak). A deviation from any other cell is reported
and discussed, not hidden.

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

`scripts/00_versions.sh` writes `results/versions.txt`: `docker version`,
`docker buildx version`, BuildKit version (from the builder node and the
`registry:2`/moby buildkit image digest), `gh --version`, host OS. Captured at run
time, not now.

## 9. Deviations policy

Any departure from this plan (added pattern, changed probe, failed control) is logged
in `docs/RESULTS.md` under "Deviations from pre-registration" with the reason. This
file is not rewritten.
