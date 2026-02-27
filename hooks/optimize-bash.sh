#!/bin/bash
# PreToolUse hook: delegate to Python script for JSON processing.
# Cross-platform: works on Windows Git Bash, WSL, Linux, and macOS.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cross-platform Python resolution
# python3 (Linux/Mac/WSL) → python (Windows Git Bash) → Windows install paths
# Windows の python3 は Microsoft Store スタブにリダイレクトされて
# 動かないため、--version で実際に動くかを確認する (exit 0 = OK)
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
  [ -z "$PYTHON" ] && exit 0  # No Python found, skip hook silently
fi

"$PYTHON" "$SCRIPT_DIR/optimize-bash.py"
