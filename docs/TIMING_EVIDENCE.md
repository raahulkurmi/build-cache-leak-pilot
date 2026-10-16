# Timing evidence (GitHub server-side push records)

Queried at 2026-10-16T20:57:36Z with the GitHub CLI. Raw output is reproduced below, pretty-printed with `jq` and otherwise unchanged.
GitHub keeps repository events for about 90 days, so this file preserves them.

> The pre-rewrite commits referenced here were purged from GitHub on request to remove
> personal data; this file records what GitHub's server reported before the purge. It
> cannot be re-checked independently after the purge.

## Summary

All timestamps are UTC and were recorded by GitHub's servers, not by the author.

| Server time | Record | Branch head before → after |
|---|---|---|
| 2026-10-05T15:54:58Z | branch_creation (`main`) | (none) → `3fb359c` |
| 2026-10-05T16:57:40Z | push | `3fb359c` → `eb13c54` |
| 2026-10-05T20:34:26Z | force_push (first history rewrite) | `eb13c54` → `66cddeb` |

Neither API lists the commits contained in a push. Only the before and after heads are
recorded.

## Tree-hash matches (checked 2026-10-16T21:06:06Z)

On 2026-10-16 (UTC), the author fetched each pushed commit from GitHub by SHA
(`gh api repos/raahulkurmi/build-cache-leak-pilot/git/commits/<sha>`). Its tree hash was
then compared with the commits in the current history. Identical trees mean identical
file contents. The "Current commit" column refers to the history after the
2026-10-17 (IST) rewrite (see [COMMIT_MAP.md](COMMIT_MAP.md)).

| Pushed commit (GitHub) | Tree reported by GitHub | Current commit | Current tree | Match |
|---|---|---|---|---|
| `f7310b33886915d7f8af11537fe738206515c14a` (ancestor of first head) | `018ecd4c413c01a787c4e4732b6c2ede472e0988` | `8b9e1b7bd835545e4b95958df96e67b0e28959c4` Pre-registration | `018ecd4c413c01a787c4e4732b6c2ede472e0988` | identical |
| `74cd563db4e4d8f60130ed90d1d5aeed765299be` (ancestor of first head) | `3f3e16ac2a2d0b6195af50847070b10690873c53` | `1bf7415dddae622dd17937e46f95a5291042dde4` Pre-run harness fixes | `3f3e16ac2a2d0b6195af50847070b10690873c53` | identical |
| `3fb359c45c9164ce4e941c7df9d44a94ecd7addb` (head at branch creation) | `b5eb227945bc11cc795aaa765e42e3ed93380403` | `65b225e71d9d6928455711a632e6216abcbc8d0b` (`prereg-v1`) | `b5eb227945bc11cc795aaa765e42e3ed93380403` | identical |
| `eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5` (head after push) | `71a96707e8f267260347d6056d7593a8c6e09a26` | `1da575f8740230b3bbad1ba4b0c3b7346fde04e4` Raw results | `4cc49674c23e85b6dae47baf42b5f68f6027aad2` | identical to the pre-2026-10-17 commit `0092d63`; the current tree differs only by the one-line hostname redaction in `results/versions.txt` |
| `66cddebef5b911458ae64a187003a4c564569df6` (head after force push) | `4261e1acc469a0edf27aa267de68c862fcdc5ad1` | `d30856957733b364fe23ef41643cf844675003ab` | `6ec6d12e173cfb563b1293047193866dd64d403d` | differs only by the same one-line redaction |

What the data shows:

- The pre-registration tree (`prereg-v1`, now `65b225e`) was the head of `main` on
  GitHub at 2026-10-05T15:54:58Z.
- The first commit containing results (`eb13c54`, now `1da575f`) reached GitHub at
  2026-10-05T16:57:40Z, about 62 minutes later.

What the data does not show:

- When the experiment was actually run on the author's machine.
- Whether any result existed locally before 15:54:58Z.
- Any push of the `prereg-v1` tag. Neither API returned a tag record.

## Raw: `gh api repos/raahulkurmi/build-cache-leak-pilot/events --paginate`

```json
[
  {
    "id": "23190504028",
    "type": "CreateEvent",
    "actor": {
      "id": 132373350,
      "login": "raahulkurmi",
      "display_login": "raahulkurmi",
      "gravatar_id": "",
      "url": "https://api.github.com/users/raahulkurmi",
      "avatar_url": "https://avatars.githubusercontent.com/u/132373350?"
    },
    "repo": {
      "id": 1406023747,
      "name": "raahulkurmi/build-cache-leak-pilot",
      "url": "https://api.github.com/repos/raahulkurmi/build-cache-leak-pilot"
    },
    "payload": {
      "ref": "main",
      "ref_type": "branch",
      "full_ref": "refs/heads/main",
      "master_branch": "main",
      "description": null,
      "pusher_type": "user"
    },
    "public": false,
    "created_at": "2026-10-05T15:54:59Z"
  },
  {
    "id": "23097000370",
    "type": "PushEvent",
    "actor": {
      "id": 132373350,
      "login": "raahulkurmi",
      "display_login": "raahulkurmi",
      "gravatar_id": "",
      "url": "https://api.github.com/users/raahulkurmi",
      "avatar_url": "https://avatars.githubusercontent.com/u/132373350?"
    },
    "repo": {
      "id": 1406023747,
      "name": "raahulkurmi/build-cache-leak-pilot",
      "url": "https://api.github.com/repos/raahulkurmi/build-cache-leak-pilot"
    },
    "payload": {
      "repository_id": 1406023747,
      "push_id": 45546972113,
      "ref": "refs/heads/main",
      "head": "66cddebef5b911458ae64a187003a4c564569df6",
      "before": "eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5"
    },
    "public": false,
    "created_at": "2026-10-05T20:34:26Z"
  },
  {
    "id": "23080692363",
    "type": "PushEvent",
    "actor": {
      "id": 132373350,
      "login": "raahulkurmi",
      "display_login": "raahulkurmi",
      "gravatar_id": "",
      "url": "https://api.github.com/users/raahulkurmi",
      "avatar_url": "https://avatars.githubusercontent.com/u/132373350?"
    },
    "repo": {
      "id": 1406023747,
      "name": "raahulkurmi/build-cache-leak-pilot",
      "url": "https://api.github.com/repos/raahulkurmi/build-cache-leak-pilot"
    },
    "payload": {
      "repository_id": 1406023747,
      "push_id": 45528533956,
      "ref": "refs/heads/main",
      "head": "eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5",
      "before": "3fb359c45c9164ce4e941c7df9d44a94ecd7addb"
    },
    "public": false,
    "created_at": "2026-10-05T16:57:41Z"
  }
]
```

## Raw: `gh api "repos/raahulkurmi/build-cache-leak-pilot/activity?per_page=100" --paginate`

```json
[
  {
    "id": 45546972113,
    "node_id": "PSH_kwLOU844Q88AAAAKms-j0Q",
    "before": "eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5",
    "after": "66cddebef5b911458ae64a187003a4c564569df6",
    "ref": "refs/heads/main",
    "timestamp": "2026-10-05T20:34:26Z",
    "activity_type": "force_push",
    "actor": {
      "login": "raahulkurmi",
      "id": 132373350,
      "node_id": "U_kgDOB-PbZg",
      "avatar_url": "https://avatars.githubusercontent.com/u/132373350?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/raahulkurmi",
      "html_url": "https://github.com/raahulkurmi",
      "followers_url": "https://api.github.com/users/raahulkurmi/followers",
      "following_url": "https://api.github.com/users/raahulkurmi/following{/other_user}",
      "gists_url": "https://api.github.com/users/raahulkurmi/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/raahulkurmi/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/raahulkurmi/subscriptions",
      "organizations_url": "https://api.github.com/users/raahulkurmi/orgs",
      "repos_url": "https://api.github.com/users/raahulkurmi/repos",
      "events_url": "https://api.github.com/users/raahulkurmi/events{/privacy}",
      "received_events_url": "https://api.github.com/users/raahulkurmi/received_events",
      "type": "User",
      "user_view_type": "public",
      "site_admin": false
    }
  },
  {
    "id": 45528533956,
    "node_id": "PSH_kwLOU844Q88AAAAKmbZLxA",
    "before": "3fb359c45c9164ce4e941c7df9d44a94ecd7addb",
    "after": "eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5",
    "ref": "refs/heads/main",
    "timestamp": "2026-10-05T16:57:40Z",
    "activity_type": "push",
    "actor": {
      "login": "raahulkurmi",
      "id": 132373350,
      "node_id": "U_kgDOB-PbZg",
      "avatar_url": "https://avatars.githubusercontent.com/u/132373350?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/raahulkurmi",
      "html_url": "https://github.com/raahulkurmi",
      "followers_url": "https://api.github.com/users/raahulkurmi/followers",
      "following_url": "https://api.github.com/users/raahulkurmi/following{/other_user}",
      "gists_url": "https://api.github.com/users/raahulkurmi/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/raahulkurmi/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/raahulkurmi/subscriptions",
      "organizations_url": "https://api.github.com/users/raahulkurmi/orgs",
      "repos_url": "https://api.github.com/users/raahulkurmi/repos",
      "events_url": "https://api.github.com/users/raahulkurmi/events{/privacy}",
      "received_events_url": "https://api.github.com/users/raahulkurmi/received_events",
      "type": "User",
      "user_view_type": "public",
      "site_admin": false
    }
  },
  {
    "id": 45522775662,
    "node_id": "PSH_kwLOU844Q88AAAAKmV5ubg",
    "before": "0000000000000000000000000000000000000000",
    "after": "3fb359c45c9164ce4e941c7df9d44a94ecd7addb",
    "ref": "refs/heads/main",
    "timestamp": "2026-10-05T15:54:58Z",
    "activity_type": "branch_creation",
    "actor": {
      "login": "raahulkurmi",
      "id": 132373350,
      "node_id": "U_kgDOB-PbZg",
      "avatar_url": "https://avatars.githubusercontent.com/u/132373350?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/raahulkurmi",
      "html_url": "https://github.com/raahulkurmi",
      "followers_url": "https://api.github.com/users/raahulkurmi/followers",
      "following_url": "https://api.github.com/users/raahulkurmi/following{/other_user}",
      "gists_url": "https://api.github.com/users/raahulkurmi/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/raahulkurmi/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/raahulkurmi/subscriptions",
      "organizations_url": "https://api.github.com/users/raahulkurmi/orgs",
      "repos_url": "https://api.github.com/users/raahulkurmi/repos",
      "events_url": "https://api.github.com/users/raahulkurmi/events{/privacy}",
      "received_events_url": "https://api.github.com/users/raahulkurmi/received_events",
      "type": "User",
      "user_view_type": "public",
      "site_admin": false
    }
  }
]
```

## Raw: pushed commits, `gh api repos/raahulkurmi/build-cache-leak-pilot/git/commits/<sha>` (fetched 2026-10-16T20:57Z)

Fields: sha, tree, parents, author and committer dates. Other fields, including commit
messages, are omitted.

```json
[
  {
    "author_date": "2026-10-05T14:20:25Z",
    "committer_date": "2026-10-05T14:20:25Z",
    "parents": [],
    "sha": "f7310b33886915d7f8af11537fe738206515c14a",
    "tree": "018ecd4c413c01a787c4e4732b6c2ede472e0988"
  },
  {
    "author_date": "2026-10-05T15:42:24Z",
    "committer_date": "2026-10-05T15:42:24Z",
    "parents": [
      "f7310b33886915d7f8af11537fe738206515c14a"
    ],
    "sha": "74cd563db4e4d8f60130ed90d1d5aeed765299be",
    "tree": "3f3e16ac2a2d0b6195af50847070b10690873c53"
  },
  {
    "author_date": "2026-10-05T15:52:49Z",
    "committer_date": "2026-10-05T15:52:49Z",
    "parents": [
      "74cd563db4e4d8f60130ed90d1d5aeed765299be"
    ],
    "sha": "3fb359c45c9164ce4e941c7df9d44a94ecd7addb",
    "tree": "b5eb227945bc11cc795aaa765e42e3ed93380403"
  },
  {
    "author_date": "2026-10-05T16:51:25Z",
    "committer_date": "2026-10-05T16:51:25Z",
    "parents": [
      "3fb359c45c9164ce4e941c7df9d44a94ecd7addb"
    ],
    "sha": "eb13c549f682f34eb9d5370fe2b8e5c2187cc0d5",
    "tree": "71a96707e8f267260347d6056d7593a8c6e09a26"
  }
]
```
