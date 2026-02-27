#!/bin/bash
set -euo pipefail

# claude-dotfiles setup script
# Deploys Claude Code global config (~/.claude/) on any machine.
# Idempotent: safe to run multiple times.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "=== claude-dotfiles setup ==="
echo "Source:  $REPO_DIR"
echo "Target:  $CLAUDE_DIR"
echo

# --- 1. Install hooks ---
echo "[1/4] Installing hooks..."
mkdir -p "$HOOKS_DIR"
cp "$REPO_DIR/hooks/optimize-bash.sh" "$HOOKS_DIR/optimize-bash.sh"
cp "$REPO_DIR/hooks/optimize-bash.py" "$HOOKS_DIR/optimize-bash.py"
chmod +x "$HOOKS_DIR/optimize-bash.sh"
echo "  -> Copied hooks to $HOOKS_DIR"

# --- 2. Merge hooks into settings.json ---
echo "[2/4] Merging hook settings into settings.json..."

# Resolve Python for the merge script (same logic as the hook itself)
if command -v python3 &>/dev/null && python3 --version &>/dev/null; then
  PYTHON=python3
elif command -v python &>/dev/null && python --version &>/dev/null; then
  PYTHON=python
else
  # Fallback: search common Windows Python install locations
  PYTHON=""
  for p in /c/Users/*/AppData/Local/Programs/Python/Python3*/python.exe \
           /c/Python3*/python.exe; do
    if [ -x "$p" ] && "$p" --version &>/dev/null; then
      PYTHON="$p"
      break
    fi
  done
  if [ -z "$PYTHON" ]; then
    echo "  ERROR: Python not found. Cannot merge settings.json."
    echo "  Please install Python 3 and re-run."
    exit 1
  fi
fi

"$PYTHON" -c "
import json, sys, os

settings_path = sys.argv[1]
hooks_path = sys.argv[2]

# Load existing settings or start fresh
if os.path.exists(settings_path):
    with open(settings_path, 'r', encoding='utf-8') as f:
        settings = json.load(f)
else:
    settings = {}

# Load hook template
with open(hooks_path, 'r', encoding='utf-8') as f:
    hooks_template = json.load(f)

# Merge: replace the hooks key entirely (our hooks are the source of truth)
settings['hooks'] = hooks_template['hooks']

with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')

print('  -> Merged hooks into', settings_path)
" "$SETTINGS_FILE" "$REPO_DIR/settings-hooks.json"

# --- 3. Install CLAUDE.md ---
echo "[3/4] Installing CLAUDE.md..."
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  # No existing file: just copy
  cp "$REPO_DIR/CLAUDE.md" "$CLAUDE_MD"
  echo "  -> Copied CLAUDE.md"
elif diff -q "$REPO_DIR/CLAUDE.md" "$CLAUDE_MD" &>/dev/null; then
  echo "  -> CLAUDE.md already up to date"
else
  # Existing file differs: replace with repo version
  # (The repo is the source of truth for global rules)
  cp "$REPO_DIR/CLAUDE.md" "$CLAUDE_MD"
  echo "  -> Updated CLAUDE.md (replaced with repo version)"
fi

# --- 4. Register GitHub MCP Server ---
echo "[4/4] Registering GitHub MCP server..."
if command -v claude &>/dev/null; then
  claude mcp add --transport http github https://api.githubcopilot.com/mcp/ 2>/dev/null || true
  echo "  -> GitHub MCP server registered"
else
  echo "  -> claude CLI not found, skipping MCP registration"
  echo "     Run manually: claude mcp add --transport http github https://api.githubcopilot.com/mcp/"
fi

echo
echo "=== Setup complete ==="
echo "Restart Claude Code for changes to take effect."
