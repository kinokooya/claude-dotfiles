# claude-dotfiles

Cross-platform dotfiles for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Manages `~/.claude/` configuration across Windows, WSL, Linux, and macOS.

## What's included

| File | Purpose |
|------|---------|
| `hooks/optimize-bash.sh` | PreToolUse hook entry point (cross-platform Python resolver) |
| `hooks/optimize-bash.py` | Suppresses verbose output from `pip install`, `winget`, `ollama pull` |
| `settings-hooks.json` | Hook registration template (merged into `settings.json`) |
| `CLAUDE.md` | Global development rules (token optimization, workflow conventions) |
| `setup.sh` | One-command setup script |

## Setup

```bash
git clone https://github.com/abeshek/claude-dotfiles.git
cd claude-dotfiles
bash setup.sh
```

The setup script is idempotent — safe to run multiple times.

### What `setup.sh` does

1. Copies hook scripts to `~/.claude/hooks/`
2. Merges hook settings into `~/.claude/settings.json` (preserves existing settings)
3. Installs `~/.claude/CLAUDE.md`
4. Registers GitHub MCP server via `claude mcp add`

## Requirements

- Bash (Git Bash on Windows, or any Unix shell)
- Python 3.x
- Claude Code CLI (optional, for MCP registration)

## Hook: optimize-bash

Automatically reduces token usage by modifying Bash tool commands:

- `pip install foo` → `pip install -q foo`
- `winget install foo` → `winget install foo 2>&1 | tail -5`
- `ollama pull model` → `ollama pull model 2>&1 | tail -3`

## Cross-platform support

The hook uses runtime Python detection instead of hardcoded paths:

| Platform | Python binary |
|----------|--------------|
| Linux / macOS / WSL | `python3` |
| Windows (Git Bash) | `python` |

If neither is available, the hook exits silently (no error, no modification).
