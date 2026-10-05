# Ethics statement

Binding rules for this study. If any step would violate one of these, it is not run.

1. **No third-party content, ever.** We never download, scan, or store cache layers or
   image content we did not produce. All probing targets only artifacts this study
   pushed to our own local `registry:2` at `localhost:5000`.
2. **Synthetic secrets only.** Every "secret" is a locally generated, clearly-fake
   marker of the form `FAKE-SECRET-<P>-<hex>-DO-NOT-USE`. No real credential, token,
   `.npmrc` auth, or key is used anywhere.
3. **No AWS / no cloud.** No cloud provider is involved in any part of the study.
4. **GitHub: metadata only, within limits.** Part 2 records only `total_count` from
   code search, plus the query string and date. No repository names, owners, or file
   contents are fetched, stored, or published. Requests are throttled under the
   authenticated code-search rate limit.
5. **Own accounts only.** Runs on the author's machine, GitHub account, and a registry
   the author owns.
