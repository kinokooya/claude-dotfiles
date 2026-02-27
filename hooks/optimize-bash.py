"""PreToolUse hook: suppress verbose output from package managers.

Reduces context/token usage by automatically adding quiet flags
or piping to tail for commands with excessive progress output.
"""
import json
import sys


def main() -> None:
    data = json.load(sys.stdin)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = data.get("tool_input", {}).get("command", "")
    if not cmd:
        sys.exit(0)

    modified = False

    # pip install: add -q flag
    if "pip install" in cmd and " -q" not in cmd:
        cmd = cmd.replace("pip install", "pip install -q")
        modified = True

    # winget: suppress progress output
    if "winget install" in cmd or "winget upgrade" in cmd:
        cmd = cmd + " 2>&1 | tail -5"
        modified = True

    # ollama pull: suppress progress output
    if "ollama pull" in cmd or "ollama.exe pull" in cmd:
        cmd = cmd + " 2>&1 | tail -3"
        modified = True

    if modified:
        result = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "updatedInput": {"command": cmd},
            }
        }
        print(json.dumps(result))
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
