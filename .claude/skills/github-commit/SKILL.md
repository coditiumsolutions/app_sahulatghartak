---
name: github-commit
description: >-
  Safe Git commits with brief prefixed messages, secret scanning, and
  .gitignore hygiene. Use whenever the user asks to commit, push changes,
  save work to git, create a commit, stage files, or says "commit and push
  to github" (the primary activation phrase — always use this skill for that).
  Also triggers on casual phrasing ("commit this", "git it up", "push to
  github"). Use before any git operation that might touch merges or conflicts.
  Do NOT use for pull requests, branch strategy, or code review without a
  commit request.
author: Rayder
version: 1.1.0
---

<!-- Author: Rayder | Version: 1.1.0 -->

# GitHub Commit

Commit only when the user explicitly asks. Never commit proactively.

## Activation

**Primary phrase:** `commit and push to github`

When the user says this (or a close variant — e.g. "commit and push to GitHub", "commit & push to github"), treat it as full activation:

1. Run the complete workflow in this skill (secret scan → stage → commit with prefixed subject + body).
2. **Then push** to the remote after a successful commit (`git push`, or `git push -u origin <branch>` when upstream is not set).

If the user asks to **commit only** (no "push" in the request), commit locally and do not push unless they ask separately.

## Commit message format

**Subject line:** One line, clean and brief. Start with exactly one of these prefixes (including the colon):

| Prefix | Use when |
|--------|----------|
| `Add:` | New files, features, endpoints, or capabilities |
| `Update:` | Changes to existing behavior, config tweaks, or dependency version bumps |
| `Refactor:` | Structural or internal changes with no behavior change |
| `Fix:` | Bug fixes, error corrections, regressions |
| `Feat:` | A user-facing capability that spans multiple areas or the whole project |
| `Feat(scope):` | Same as `Feat`, but scoped to a named domain, module, or subsystem — e.g. `Feat(Auth):`, `Feat(Billing):`, `Feat(Search):`. The scope should be a short noun matching a folder, layer, or product area. Use plain `Feat:` when the change cuts across multiple areas. |
| `Remove:` | Deletions, deprecations, dead code removal |
| `Docs:` | README, comments, changelogs, or any documentation-only changes |
| `Test:` | Adding, fixing, or restructuring tests — no production code changes |
| `Perf:` | Performance improvements with no behavior change |
| `Style:` | Formatting, whitespace, linting — zero logic change |
| `Build:` | Build system changes, compilation config, bundler or toolchain setup |
| `Ci:` | CI/CD pipelines, build tooling, dependency lockfiles, and non-production housekeeping that doesn't fit another category |
| `Revert:` | Explicitly reverting a previous commit — reference the original in the body |

**Pattern:** `Prefix: short imperative summary in plain language`

**Body (default):** After a blank line, add a short body that explains *why* the change was made — bullet points or paragraphs. Focus on intent and impact, not a file list.

**Example with body:**
```
Fix: paid amount not updating after partial payment insert

Payment rows were inserted without syncing the invoice paid amount.
Update paid amount on each insert so the running balance stays correct.
```

**Subject-only examples:**
- `Add: student fee allocation check during invoice generation`
- `Update: rate limit config in API gateway`
- `Refactor: split user service into auth and profile modules`
- `Feat(Billing): late fee applied when past due date`
- `Remove: unused logger middleware`
- `Docs: add setup steps to README`
- `Test: cover edge cases in discount calculation`
- `Perf: cache repeated DB lookups in report generation`
- `Style: apply linter rules across src/`
- `Build: migrate bundler from Webpack to Vite`
- `Ci: add lint and test steps to PR workflow`
- `Revert: undo rate limiter change from previous commit`

Pick the prefix that best matches the **primary intent** of the diff. Do not combine prefixes on the subject line.

## Pre-commit workflow

Run these in parallel before staging:

```bash
git status
git diff
git diff --cached
git log -3 --oneline
```

Use recent commit style as a tiebreaker when the best prefix is ambiguous.

### 1. Secret and credential scan (mandatory)

Before `git add`, inspect **staged and unstaged** changes for sensitive data. Never commit:

| Blocked | Notes |
|---------|-------|
| `.env`, `.env.local`, `.env.*` | **Exception:** `*.example`, `*.example.env`, files clearly named as templates with **no real secrets** |
| Connection strings | Any config file or code containing real hostnames, passwords, or credentials |
| API keys, tokens, passwords | Including cloud provider keys, JWT secrets, SMTP credentials, OAuth secrets |
| Local config overrides | e.g. `appsettings.Development.json`, `config.local.*`, `*.local.json` |
| Certificates and private keys | `.pfx`, `.pem`, `.key`, `.p12` with private key material |
| Secret store files | `credentials.json`, `secrets.json`, `*.secrets.*`, `keystore.*` |

Scan commands:

```bash
git diff --name-only
git diff
```

Flag patterns: `password`, `passwd`, `pwd=`, `secret`, `api_key`, `apikey`, `Bearer `, `token`, `sk-`, `ghp_`, `AKIA`, `AccountKey=`, `private_key`, base64 blobs in config files.

**If secrets are found:**
1. **Stop** — do not commit those files.
2. Tell the user what was found and where.
3. Move secrets to environment variables, a secrets manager, or local-only config excluded from version control.
4. Add or update `.gitignore` (see below).
5. If a file was already committed historically, warn the user; do not rewrite history unless they explicitly ask.

For extended patterns, read [references/secrets-patterns.md](references/secrets-patterns.md).

### 2. .gitignore hygiene

If a sensitive or generated path is not already ignored, append to `.gitignore` **before** committing other work:

```
# Secrets and local config
.env
.env.*
!.env.example
*.local.json
**/secrets.json
**/credentials.json
```

Add project-appropriate entries for your stack's build artifacts and local tooling (e.g. `dist/`, `build/`, `node_modules/`, `.next/`, `__pycache__/`, `*.pyc`, `bin/`, `obj/`, `.vs/`). Prefer inserting into existing `.gitignore` sections rather than appending loosely.

### 3. Stage only intended files

- Do not stage build output, dependency folders, or editor artifacts unless the user explicitly asks.
- Do not stage files that failed the secret scan.
- Warn if the user asked to commit a file that looks like it contains secrets.

## Commit execution

**Git safety (non-negotiable):**
- Never change `git config`
- Never use `--no-verify`, `--no-gpg-sign`, or skip hooks unless the user explicitly requests it
- Never `push --force` to `main`/`master` without explicit user approval; warn if they ask
- Avoid `git commit --amend` unless: user asked, HEAD was created in this session, and the commit was not pushed

**Sequence:**
1. Complete secret scan and `.gitignore` updates
2. `git add` only approved paths
3. Commit with the formatted message

When the message has a body, use a here-string (PowerShell) or `-m` twice (bash) to avoid shell escaping issues:

```bash
# bash / zsh
git commit -m "Fix: paid amount not updating after partial payment insert" \
           -m "Payment rows were inserted without syncing the invoice paid amount. Update paid amount on each insert so the running balance stays correct."
```

```powershell
# PowerShell
git commit -m @"
Fix: paid amount not updating after partial payment insert

Payment rows were inserted without syncing the invoice paid amount.
Update paid amount on each insert so the running balance stays correct.
"@
```

Single-line commits are fine when the change is trivial and needs no explanation.

4. `git status` after commit to confirm success.

**After commit — push (when activated):** If the user used the activation phrase or explicitly asked to push:

```bash
git push
# or, if no upstream is set yet:
git push -u origin HEAD
```

Report the push result (branch, remote, commits pushed). Never force-push to `main`/`master` without explicit approval.

## Merges and conflicts — always ask first

**Never** run these without explicit user approval in the current message:
- `git merge`, `git pull` (when it merges), `git rebase`, `git cherry-pick`
- Resolving conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- `git checkout --theirs` / `--ours` on conflicted files
- `git reset --hard`, `git push --force`

If a commit attempt surfaces merge conflicts or a dirty merge state:
1. Stop
2. Explain what conflicted (files and branches involved)
3. Present options (pull first, abort, manual resolution)
4. Wait for the user to choose

## When commit fails

- Hook rejected commit → fix the issue, create a **new** commit (do not amend unless amend rules apply)
- Nothing to commit → say so; do not create an empty commit

## Checklist (mental)

```
- [ ] User explicitly asked to commit
- [ ] No secrets, .env (except safe examples), or credentials in the staged diff
- [ ] .gitignore updated if needed
- [ ] Subject uses one allowed prefix; body explains why when the change is non-trivial
- [ ] No merge/conflict operations without user approval
- [ ] git status clean after commit (or remaining state explained)
- [ ] Pushed to GitHub when activation phrase or explicit push was requested
```