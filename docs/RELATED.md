# Related work: secret exposure via container build caches

Search done 2026-10-05, before writing RESULTS.md. This was a web search only: about 10
queries, plus a read of each source listed below. We did not do a systematic search of
the ACM DL, IEEE Xplore or USENIX proceedings. "Not found" below means we did not find
it with this search. It does not mean the work doesn't exist.

Each source is placed in one of four coverage classes:

- **MEASURES**: an empirical measurement of whether secrets can be recovered.
- **SINGLE CASE**: one worked example, with no measurement.
- **ASSERTS**: documentation or advice that states the risk, with no evidence attached.
- **ADJACENT**: about a different property (integrity, not confidentiality) or a different
  artifact (final images, CI artifacts, workflows).

## 1. Secrets in published container images (final images)

| Source | Class | What it covers | What it does not cover |
|---|---|---|---|
| Dahlmanns, Sander, Decker, Wehrle. *Secrets Revealed in Container Images: An Internet-wide Study on Occurrence and Impact.* ASIA CCS 2023. [ACM DL](https://dl.acm.org/doi/10.1145/3579856.3590329) · [arXiv 2307.03958](https://arxiv.org/abs/2307.03958) · [code](https://github.com/COMSYS/docker-secret-analysis) | MEASURES (final images) | 337,171 Docker Hub images plus 8,076 other registries. 8.5% of images contain secrets, including 52,107 private keys and 3,158 API secrets. Scans the distinct layers of the selected tags (usually `latest`) and the ENV values in the image config. | Published images pulled from registries only. Scope confirmed by grepping the full text of the arXiv HTML rendering of 2307.03958 (~17k words, read 2026-10-06; not the ACM camera-ready, whose ACM DL page returned HTTP 403 to our fetch on 2026-10-06): 0 occurrences of "BuildKit", "multi-stage", "attestation", "provenance" or "intermediate". All 5 occurrences of "cache" refer to browser caches *inside* images (e.g. `/headless/.cache/mozilla`), not build caches. Method as stated in the text: "we analyze each distinct layer only once"; images "preferably" tagged `latest`; regexes matched "on files and environment variables". |
| Kapelinski, Machado, Kreutz. *Vulnerabilities, Secrets and Misconfiguration in the Highest-Exposure Docker Hub Images.* arXiv 2608.02669, Aug 2026. [arXiv](https://arxiv.org/abs/2608.02669) | MEASURES (final images) | Scans the 52,895 highest-exposure Docker Hub repositories (ranked by an exposure score built from pull counts) with 6 scanners, after rebuilding the layer graph. Hand-labelling 1,100 random TruffleHog detections found 99.7% were not credentials. | The abstract doesn't mention build caches or attestations. We didn't read past the abstract for this one. |
| Leon (Truffle Security). *How Secrets Leak out of Docker Images.* Blog, 2023-09-11. [link](https://trufflesecurity.com/blog/how-secrets-leak-out-of-docker-images) | ASSERTS (final images) | Explains layer leaks and cites Dahlmanns. | No cache, intermediate-stage or attestation coverage, and no new numbers. |

## 2. Build-args in SLSA provenance attestations

| Source | Class | What it covers | What it does not cover |
|---|---|---|---|
| Docker docs, *Provenance attestations*. [link](https://docs.docker.com/build/metadata/attestations/slsa-provenance/) | ASSERTS | Verbatim: "mode=max exposes the values of build arguments." And: "Values of build arguments, the identities of secrets, and rich layer metadata are not included in mode=min." Secret mounts "are never included in provenance attestations." | Documentation only. Gives no version-specific test and no measurement. |
| Kothari. *Leaked Build Arguments in Multi-stage Docker Builds via Build Attestations.* Blog, 2023-06-10. [link](https://ricekot.com/2023/docker-provenance-attestations/) | SINGLE CASE | Shows a build-arg recovered through `imagetools inspect` from the provenance attestation on a pushed image (BuildKit ≥ 0.11 / buildx ≥ 0.10). Points out that keeping the arg in a throwaway multi-stage builder doesn't help. | One example. No control, no min-vs-max comparison, no prevalence numbers, and registry build caches aren't discussed. |

## 3. Registry build cache (`--cache-to type=registry,mode=max`)

| Source | Class | What it covers | What it does not cover |
|---|---|---|---|
| Docker docs, *Cache storage backends*. [link](https://docs.docker.com/build/cache/backends/) | ASSERTS | Defines the modes: in `min`, "only layers that are exported into the resulting image are cached, while in `max` cache mode, all layers are cached, even those of intermediate steps." General warning that managing secrets through `COPY` or `ARG` "could result in leaked credentials." | Doesn't tie the warning to `mode=max` cache exports specifically, and measures nothing. |
| OneUptime blog, *Fix Vanishing Multi-Stage Docker Caches in CI with BuildKit mode=max*, 2026-08-03. [link](https://oneuptime.com/blog/post/2026-08-03-why-multi-stage-docker-cache-vanishes-ci-buildkit-mode-max/view) | ASSERTS | Says that `mode=max` cache blobs pushed to a shared or public registry can leak secrets or leftover files, and mentions env vars as an example. | Gives no evidence. The env-var part of that claim is the one this study's P2 result bears on. |

**We found nothing that MEASURES whether secrets can be recovered from a registry build-cache export.** We also found nothing that compares cache min vs max, or provenance min vs max, against a validated `--mount=type=secret` control.

## 4. CI caches and artifacts (adjacent: integrity, or a different artifact)

| Source | Class | What it covers | What it does not cover |
|---|---|---|---|
| Koishybayev et al. *Characterizing the Security of GitHub CI Workflows.* USENIX Security 2022. [link](https://www.usenix.org/conference/usenixsecurity22/presentation/koishybayev) | MEASURES (workflows) | 447,238 workflows across 213,854 repositories. Covers workflow privileges and secret access. | Doesn't cover what build caches contain. |
| Khan. *Cacheract: The Monster in your Build Cache.* Blog, 2024-12-21. [link](https://adnanthekhan.com/2024/12/21/cacheract-the-monster-in-your-build-cache/) · Khan, *Angular compromise through dev-infra* [link](https://adnanthekhan.com/posts/angular-compromise-through-dev-infra/) | SINGLE CASE (integrity) | GitHub Actions cache **poisoning**, i.e. writing malicious entries that a privileged workflow later restores. | About integrity, not confidentiality. Not about BuildKit registry caches. |
| SecurityWeek coverage of Palo Alto Networks research on GitHub Actions artifacts leaking tokens, 2024. [link](https://www.securityweek.com/github-actions-artifacts-leak-tokens-and-expose-cloud-services-and-repositories/) | MEASURES (CI artifacts) | Secrets found in public workflow artifacts. | These are uploaded artifacts, not build caches. We read the news coverage only, not the primary report. |

## Summary for the contribution paragraph

- **Final images:** measured at scale (Dahlmanns 2023, Kapelinski 2026). Not new.
- **Build-args in max provenance:** documented by Docker and shown in one example by Kothari (2023). Not new as a leak, but we found no controlled min-vs-max measurement pinned to a specific version.
- **Registry build cache, `mode=max`:** stated as a risk in docs and blogs. **We found no measurement**, and in particular nothing that separates the filesystem channel (layers) from the config channel (ENV/ARG).
- **CI cache poisoning:** a different property (integrity).

So our contribution should be described as a pre-registered **measurement and channel breakdown** of a known risk, with a validated control and version pinning. It is not a new leak class. The P2 result (builder-stage ENV is not in the max cache export) contradicts part of the assertion in the OneUptime post.
