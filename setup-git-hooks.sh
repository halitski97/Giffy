#!/bin/sh
# One-time setup for Giffy: creates git hooks, Claude Code permissions and SwiftLint config
# in the right places and enables the hooks. Run from the repo root:  sh setup-git-hooks.sh
set -e

if [ ! -d .git ]; then
  echo "Run this script from the repository root (the folder that contains .git)." >&2
  exit 1
fi

mkdir -p .githooks .claude

cat > .githooks/pre-commit <<'EOF'
#!/bin/sh
# Giffy pre-commit hook.
# 1. Commits are made by the developer, never by Claude Code.
# 2. Staged Swift files must pass SwiftLint (warnings count as errors).

# Git GUIs (Sourcetree, Xcode) run hooks with a minimal PATH, so add Homebrew explicitly.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ -n "$CLAUDE_CODE_CHILD_SESSION" ]; then
  echo "pre-commit: commits are made by the developer, not by Claude Code." >&2
  exit 1
fi

files=$(git diff --cached --name-only --diff-filter=ACM -- '*.swift')
[ -z "$files" ] && exit 0

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "pre-commit: SwiftLint is not installed (brew install swiftlint)." >&2
  exit 1
fi

if ! printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 swiftlint lint --strict --quiet --force-exclude; then
  echo "pre-commit: SwiftLint found violations. Fix them (or run 'swiftlint --fix') and commit again." >&2
  exit 1
fi
EOF

cat > .githooks/pre-push <<'EOF'
#!/bin/sh
# Giffy pre-push hook.
# 1. Pushes are made by the developer, never by Claude Code.
# 2. The whole project must pass SwiftLint (warnings count as errors).

# Git GUIs (Sourcetree, Xcode) run hooks with a minimal PATH, so add Homebrew explicitly.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ -n "$CLAUDE_CODE_CHILD_SESSION" ]; then
  echo "pre-push: pushes are made by the developer, not by Claude Code." >&2
  exit 1
fi

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "pre-push: SwiftLint is not installed (brew install swiftlint)." >&2
  exit 1
fi

if ! swiftlint lint --strict --quiet; then
  echo "pre-push: SwiftLint found violations. Fix them before pushing." >&2
  exit 1
fi
EOF

cat > .claude/settings.json <<'EOF'
{
  "permissions": {
    "deny": [
      "Bash(git commit)",
      "Bash(git commit *)",
      "Bash(git * commit)",
      "Bash(git * commit *)",
      "Bash(git push)",
      "Bash(git push *)",
      "Bash(git * push)",
      "Bash(git * push *)"
    ]
  }
}
EOF

cat > .swiftlint.yml <<'EOF'
# SwiftLint configuration for Giffy. Run `swiftlint` from the repo root.
included:
  - Giffy/Giffy
excluded:
  - docs
EOF

chmod +x .githooks/pre-commit .githooks/pre-push
git config core.hooksPath .githooks

echo "Done. core.hooksPath = $(git config core.hooksPath)"
ls -A .githooks .claude
