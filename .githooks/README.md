# Git Hooks

Local git hooks for the Coffee Journal project.

## Available Hooks

### post-commit

Runs unit tests in the background after each commit.

**Installation:**
```bash
cp .githooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

**Features:**
- ✅ Runs tests in background (doesn't block your workflow)
- ✅ Only runs unit tests (fast)
- ✅ Shows summary of results
- ✅ Continues even if tests fail (just notifies you)

**To disable:**
```bash
rm .git/hooks/post-commit
```

**To temporarily skip:**
```bash
git commit --no-verify -m "message"
```

## Why Local Hooks?

- No GitHub Actions minutes consumed
- Faster feedback (local execution)
- Works offline
- Customizable per developer

## Why post-commit instead of pre-commit?

- **pre-commit**: Blocks the commit if tests fail (can be frustrating)
- **post-commit**: Lets you commit, then notifies you (less disruptive)

If you prefer pre-commit behavior, just rename the hook to `pre-commit` and remove the `&` and `disown` lines to make it blocking.
