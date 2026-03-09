---
name: gh-copilot-review-resolve
description: Resolve selected GitHub Copilot PR review threads with cautious defaults using gh GraphQL mutations
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: github
  category: github-workflow
---

## What I do

- Accept a GitHub pull request URL or PR number
- Fetch PR review threads with GitHub GraphQL via `gh api graphql`
- Detect Copilot-authored review threads and separate unresolved ones
- Default to a cautious review-first flow: inspect first, resolve only explicitly selected threads
- Post a reply for each selected thread, then resolve it on GitHub
- Support two standard actions per thread: `addressed` and `ignored`
- Return a compact action summary including thread ids, paths, and reply URLs when available

## When to use me

Use this skill when:
- User has already handled some Copilot review comments and wants those threads resolved
- User wants to intentionally close selected Copilot suggestions as ignored with an explicit reply
- User wants a repeatable `gh` + GraphQL workflow for Copilot review-thread cleanup
- User wants to act on Copilot review threads without touching human reviewer threads by default

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- If given only a PR number, the current repository must have a GitHub `origin` remote
- The target PR must be accessible with the current GitHub credentials
- If `gh` not installed -> error: `Error: GitHub CLI not found. Install: https://cli.github.com/`
- If not authenticated -> error: `Error: Not authenticated with GitHub. Run: gh auth login`

## Input Handling

Accept either of these forms:

- Full GitHub PR URL
  - Example: `https://github.com/owner/repo/pull/123`
- PR number
  - Example: `123`

The user must also identify which Copilot threads to act on and how to handle each one.

### Supported Per-Thread Actions

- `addressed`
  - Use when the suggestion was implemented or otherwise handled in code or docs
  - Default reply template: `Addressed in <commit> (<subject>).`
- `ignored`
  - Use when the suggestion is intentionally not being applied right now
  - Default reply template: `Ignoring this suggestion for now.`

Custom reply text is allowed per thread, but these two action labels should be the default language.

### Resolution Rules

1. If input is a full PR URL:
   - Use it directly with `gh pr view <pr>` and related `gh` commands.
2. If input is a PR number:
   - Resolve repository from `git remote get-url origin`
   - Derive `owner/repo`
   - Build the API path from that repository and PR number
3. If the input is neither a valid URL nor a PR number:
   - Error: `Error: Provide a GitHub PR URL or PR number`

## Cautious Default Behavior

- Default to inspection first, action second
- Only resolve explicitly selected Copilot threads by default
- Do not bulk-resolve all unresolved Copilot threads unless the user explicitly asks for bulk mode
- Do not resolve human-authored threads unless the user explicitly asks
- Skip already resolved threads
- If a thread is marked `ignored`, still add a reply before resolving so the closure is explicit

## Workflow

1. **Validate GitHub access**
   ```bash
   gh auth status
   ```

2. **Resolve PR and fetch metadata**
   - For PR URL, use:
     ```bash
     gh pr view <pr> --json number,title,url,author,baseRefName,headRefName
     ```
   - For PR number in current repo, verify remote:
     ```bash
     git remote get-url origin
     gh pr view <number> --json number,title,url,author,baseRefName,headRefName
     ```

3. **Fetch review threads with GraphQL**
   ```bash
   query=$(cat <<'EOF'
   query($owner: String!, $repo: String!, $number: Int!, $threadCursor: String) {
     repository(owner: $owner, name: $repo) {
       pullRequest(number: $number) {
         reviewThreads(first: 100, after: $threadCursor) {
           pageInfo {
             hasNextPage
             endCursor
           }
           nodes {
             id
             isResolved
             isOutdated
             path
             line
             startLine
             comments(first: 20) {
               pageInfo {
                 hasNextPage
                 endCursor
               }
               nodes {
                 id
                 body
                 url
                 createdAt
                 author {
                   login
                 }
               }
             }
           }
         }
       }
     }
   }
   EOF
   )

   gh api graphql -f query="$query" -F owner='<owner>' -F repo='<repo>' -F number=<number>
   ```
   - Include `pageInfo { hasNextPage endCursor }` for both `reviewThreads` and `comments`
   - Continue fetching `reviewThreads` with an `after` cursor until `hasNextPage` is `false`
   - If a thread's `comments` connection has more pages, fetch the remaining comment pages with a dedicated per-thread query before deciding whether the thread is Copilot-authored

4. **Identify Copilot-authored threads**
   - Match exact known Copilot identities first, including `Copilot`, `copilot-pull-request-reviewer`, and `copilot-pull-request-reviewer[bot]`
   - Then match comment authors whose login contains `copilot`
   - Ignore human-only threads by default

5. **Preview unresolved Copilot threads before acting**
   - Summarize each unresolved Copilot thread with:
     - `thread id`
     - `path`
     - `line` or `startLine`/`line`
     - `isOutdated`
     - latest Copilot comment excerpt
   - If line metadata is missing, still show the thread using `path` and `isOutdated`; do not fail preview just because the thread no longer has line coordinates
   - If the user has not clearly identified thread actions yet, stop here and ask only for the missing thread/action mapping

6. **Determine the reply wording source for `addressed` threads**
   - If the user already provided the commit reference and subject, use it
   - Otherwise, ask the user for the commit reference before using the full template `Addressed in <commit> (<subject>).`
   - If the user does not want to supply a subject, fall back to `Addressed in <commit>.`

7. **Prepare replies for selected threads**
   - For `addressed`, prefer a commit-aware reply such as:
      - `Addressed in 66022de (fix: harden dataset scripts).`
   - For `ignored`, prefer:
      - `Ignoring this suggestion for now.`
   - If the user provided custom wording, use it exactly

8. **Reply to each selected review thread**
   ```bash
   query=$(cat <<'EOF'
   mutation($threadId: ID!, $body: String!) {
     addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
       comment {
         url
       }
     }
   }
   EOF
   )

   gh api graphql -f query="$query" -F threadId='<thread-id>' -F body='<reply-body>'
   ```

9. **Resolve each selected thread after replying**
   ```bash
   query=$(cat <<'EOF'
   mutation($threadId: ID!) {
     resolveReviewThread(input: {threadId: $threadId}) {
       thread {
         id
         isResolved
       }
     }
   }
   EOF
   )

   gh api graphql -f query="$query" -F threadId='<thread-id>'
   ```

10. **Report results**
   - Return which threads were resolved as `addressed`
   - Return which threads were resolved as `ignored`
   - Include reply URLs when available
   - Note any partial failures clearly

## Bulk Mode

Bulk mode is allowed only when the user explicitly asks for it.

- Safe bulk example: resolve these Copilot threads with one shared `addressed` reply and these other Copilot threads with one shared `ignored` reply
- Unsafe default to avoid: resolving every unresolved Copilot thread automatically with one generic message

Even in bulk mode, separate the actions into at least these groups:
- threads marked `addressed`
- threads marked `ignored`

## Copilot Thread Detection

Treat a thread as Copilot feedback when at least one review-thread comment is authored by:

- `Copilot`
- `copilot-pull-request-reviewer`
- `copilot-pull-request-reviewer[bot]`
- a login containing `copilot`

If multiple comments exist in the same thread, treat the thread as Copilot-authored if any comment clearly matches Copilot.

## Reply Message Guidelines

- Keep replies short and explicit
- Prefer commit-specific replies for `addressed` threads when a commit is known
- Do not claim a suggestion was fixed if the thread is actually being ignored
- For `ignored`, make the intentional choice clear without overexplaining

Examples:

- `Addressed in 66022de (fix: harden dataset scripts).`
- `Addressed in 66022de.`
- `Ignoring this suggestion for now.`
- `Keeping the current behavior for now; not applying this suggestion in this PR.`

## Suggested Action Summary Format

Return a concise result like:

```text
Resolved 3 Copilot threads on PR #1.

- addressed: PRRT_xxx `scripts/download_artifact_files.py` -> <reply-url>
- addressed: PRRT_yyy `scripts/resolve_maven_dependencies.py` -> <reply-url>
- ignored: PRRT_zzz `AGENTS.md` -> <reply-url>
```

## GraphQL Operations Reference

### List review threads

```bash
query=$(cat <<'EOF'
query($owner: String!, $repo: String!, $number: Int!, $threadCursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $threadCursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          startLine
          comments(first: 20) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              id
              body
              url
              createdAt
              author {
                login
              }
            }
          }
        }
      }
    }
  }
}
EOF
)

gh api graphql -f query="$query" -F owner='<owner>' -F repo='<repo>' -F number=<number>
```

Repeat the `reviewThreads` query until thread pagination is exhausted, and fetch additional comment pages for any thread whose `comments.pageInfo.hasNextPage` is `true` before classifying it.

### Fetch additional comments for one thread

```bash
query=$(cat <<'EOF'
query($threadId: ID!, $commentCursor: String) {
  node(id: $threadId) {
    ... on PullRequestReviewThread {
      id
      comments(first: 20, after: $commentCursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          body
          url
          createdAt
          author {
            login
          }
        }
      }
    }
  }
}
EOF
)

gh api graphql -f query="$query" -F threadId='<thread-id>'
```

Use this per-thread query when the nested `comments` connection reports more pages than the initial `reviewThreads` query returned.

### Reply to a review thread

```bash
query=$(cat <<'EOF'
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment {
      url
    }
  }
}
EOF
)

gh api graphql -f query="$query" -F threadId='<thread-id>' -F body='<reply-body>'
```

### Resolve a review thread

```bash
query=$(cat <<'EOF'
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}
EOF
)

gh api graphql -f query="$query" -F threadId='<thread-id>'
```

## Error Handling

- Invalid input -> `Error: Provide a GitHub PR URL or PR number`
- `gh` missing -> `Error: GitHub CLI not found. Install: https://cli.github.com/`
- Not authenticated -> `Error: Not authenticated with GitHub. Run: gh auth login`
- No GitHub remote for PR number mode -> `Error: No GitHub remote found. Provide a full PR URL or set origin`
- PR not found or inaccessible -> `Error: Unable to access the pull request with current GitHub credentials`
- No Copilot threads found -> `No Copilot-authored review threads found on this pull request`
- No unresolved Copilot threads found -> `No unresolved Copilot review threads found on this pull request`
- No explicit thread/action mapping in cautious default mode -> ask only for the missing thread ids and whether each is `addressed` or `ignored`
- Reply succeeded but resolve failed -> report partial success and include the affected thread id

## Notes

- Use `gh` CLI only; no separate GitHub SDK is required
- This skill changes GitHub review-thread state but does not edit repository files
- This skill is intentionally the action companion to `gh-copilot-review-read`
- Prefer explicit per-thread intent over aggressive automation
