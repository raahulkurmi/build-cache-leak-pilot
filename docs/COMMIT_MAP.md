# Commit map

The history of this repository has been rewritten twice. Author and committer dates,
names, commit order and messages were preserved both times.

1. **2026-10-05.** Removed co-author trailers from commit messages. For the four
   commits GitHub recorded before this rewrite, the file trees are identical before and
   after it (see [TIMING_EVIDENCE.md](TIMING_EVIDENCE.md)).
2. **2026-10-17.** Changed one author/committer email from a work address to the
   author's personal address, and replaced a hostname containing a hardware (MAC)
   address in `results/versions.txt` with `<redacted-hostname>`. Done with
   `git filter-repo`. No other content changed.

`prereg-v1` is a lightweight tag on the current pre-registration commit. It replaces an
annotated tag created after the first rewrite, so it carries no tag date of its own.

The "First push" column lists only commits that GitHub recorded as pushed before
rewrite 1 (see [TIMING_EVIDENCE.md](TIMING_EVIDENCE.md)). The other commits were created
after that push.

| # | Subject | First push (pre-rewrite 1) | After rewrite 1 | Current (after rewrite 2) |
|---|---|---|---|---|
| 1 | Pre-registration: patterns, predicted outcomes, prevalence method | `f7310b33886915d7f8af11537fe738206515c14a` | `73695c211b162075c0552c4abe1c9064fac911d1` | `8b9e1b7bd835545e4b95958df96e67b0e28959c4` |
| 2 | Pre-run harness fixes + register P2b/H1b (no experiment has been run) | `74cd563db4e4d8f60130ed90d1d5aeed765299be` | `d3546f4e345ddb1359203d3a87d58819361e5fdb` | `1bf7415dddae622dd17937e46f95a5291042dde4` |
| 3 | Pre-run: de-gate H1b from attest-min (reported, not gated); P3 placeho | `3fb359c45c9164ce4e941c7df9d44a94ecd7addb` | `51d2c559381060d13d909544df6ae9b95f3f78fc` | `65b225e71d9d6928455711a632e6216abcbc8d0b` (`prereg-v1`) |
| 4 | Raw results: Part 1 matrix + Part 2 prevalence (run at BuildKit v0.33. | `eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5` | `0092d638a0242b697779ffef1dfd402123470a3c` | `1da575f8740230b3bbad1ba4b0c3b7346fde04e4` |
| 5 | RESULTS: pre-registered outcomes, channel decomposition, prevalence bo | — | `c31389c5239d6365634276861306c08c6d45ee4a` | `750fabfc7782a4d83f3a00e8bc20a10929034530` |
| 6 | RESULTS: label process notes + add (git:) tag class for pre-registrati | — | `7aa45d96c190c59820476e4faa52b95fd7671d1f` | `8ba667a9af5a5caebb323bedf472342fe9fcc536` |
| 7 | RESULTS: scope the pre-registration claim to commit order (git-verifia | — | `bdb8791c2848fa49efedc3343f2ae3368e06b904` | `aad987d4d8ba8a1c3395e6afc77cbc3815833509` |
| 8 | RESULTS: tag item 8 timing claim to commit order. | — | `e26d21d0950c3fb9064d5f9ab61fa3386de4506f` | `7946af383abd024905503cbf4524b2d5ff149c80` |
| 9 | RESULTS: tag Section 1 de-gating timing claim to commit order. | — | `28656ee86bda0dcd5b2bfb2e29651004821f241f` | `130c990b9c0f909bdf93a5c526a0a3b10c76d47d` |
| 10 | RESULTS: update (git:) SHA refs to rewritten history after trailer str | — | `66cddebef5b911458ae64a187003a4c564569df6` | `d30856957733b364fe23ef41643cf844675003ab` |
