# Onfido Github Actions

Set of reusable workflows used by Onfido Github actions.

## Lock

A distributed lock mechanism to prevent parallel execution of integration tests across repositories. Uses a git branch in a dedicated lock repository (`onfido/ci-lock`) as an atomic mutex.

### How it works

- Lock branch **does not exist** = lock is **free**
- Lock branch **exists** = lock is **taken**

The `lock/acquire` action attempts to create a branch (e.g., `locks/client-libraries-integration-tests`) in the lock repository. Git ref creation is atomic — only one process can succeed. If it fails, the action polls until the branch is deleted (lock released) or times out.

The `lock/release` action deletes the lock branch, making the lock available again.

### Setup

1. Create the lock repository (e.g., `onfido/ci-lock`) with at least a `main` branch
2. Create a GitHub App or PAT with write access to `onfido/ci-lock`
3. Store the token as a secret in each SDK repository (e.g., `CI_LOCK_TOKEN`)

### Usage

```yaml
jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: onfido/onfido-actions/lock/acquire@main
        with:
          github-token: ${{ secrets.CI_LOCK_TOKEN }}
          lock-name: "client-libraries-integration-tests"  # optional, this is the default
          timeout: "1800"                                  # optional, default 30 min
          poll-interval: "30"                              # optional, default 30s

      # ... run your integration tests ...

      - uses: onfido/onfido-actions/lock/release@main
        if: always()
        with:
          github-token: ${{ secrets.CI_LOCK_TOKEN }}
          lock-name: "client-libraries-integration-tests"
```

### Inputs

#### `lock/acquire`

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | yes | | Token with write access to lock repo |
| `lock-name` | yes | `client-libraries-integration-tests` | Lock name (becomes branch `locks/<name>`) |
| `lock-repo` | no | `onfido/ci-lock` | Repository used for locking |
| `timeout` | no | `1800` | Max wait time in seconds |
| `poll-interval` | no | `30` | Seconds between retries |

#### `lock/release`

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | yes | | Token with write access to lock repo |
| `lock-name` | yes | `client-libraries-integration-tests` | Lock name (must match acquire) |
| `lock-repo` | no | `onfido/ci-lock` | Repository used for locking |

### Stale lock recovery

If a workflow crashes without releasing the lock, manually delete the branch:
```bash
gh api repos/onfido/ci-lock/git/refs/heads/locks/client-libraries-integration-tests -X DELETE
```

> **Important:** Always use `if: always()` on the release step to ensure the lock is freed even if tests fail.

## Changelog update

To manually update changelog, run:

```sh
RELEASE_BODY="
  - Nested changelog line from spec change
- Extra changelog line from library change
" ../onfido-action/update-changelog/update-changelog.sh
```
