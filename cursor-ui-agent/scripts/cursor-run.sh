#!/usr/bin/env bash
set -euo pipefail

# cursor-run.sh - Cursor Agent CLI wrapper script (UI design role)
# Used by cursor-ui-agent skill to call Cursor Agent with Gemini 3.1 Pro model

# Defaults
WORKDIR="."
TIMEOUT=300
MODEL="gemini-3.1-pro"
PROMPT_FILE=""
PROMPT_ARGS=""
REVIEW_MODE=false
SANDBOX=""

usage() {
    cat <<'USAGE'
Usage: cursor-run.sh [OPTIONS] [prompt...]

Options:
  --model <model>            Model to use (default: gemini-3.1-pro)
  -d, --dir <directory>      Working directory (default: current directory)
  -t, --timeout <seconds>    Timeout in seconds (default: 300)
  -f, --file <file>          Read prompt from file (recommended to avoid escaping issues)
  -r, --review               Use plan mode (read-only analysis, no file modifications)
  -s, --sandbox <mode>       Sandbox mode: enabled | disabled
  -h, --help                 Show this help message

Examples:
  cursor-run.sh "Design a login page with Tailwind CSS"
  cursor-run.sh -f /tmp/prompt.txt -d ./my-project
  cursor-run.sh --model gemini-3-flash -f /tmp/prompt.txt -d ./project
  echo "Create a dashboard component" | cursor-run.sh -d ./project
USAGE
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)
            MODEL="$2"; shift 2 ;;
        -d|--dir)
            WORKDIR="$2"; shift 2 ;;
        -t|--timeout)
            TIMEOUT="$2"; shift 2 ;;
        -f|--file)
            PROMPT_FILE="$2"; shift 2 ;;
        -r|--review)
            REVIEW_MODE=true; shift ;;
        -s|--sandbox)
            SANDBOX="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        --)
            shift; PROMPT_ARGS="$*"; break ;;
        -*)
            echo "Error: Unknown option $1" >&2; exit 1 ;;
        *)
            PROMPT_ARGS="$*"; break ;;
    esac
done

# Get prompt: file > args > stdin
if [[ -n "$PROMPT_FILE" ]]; then
    if [[ ! -f "$PROMPT_FILE" ]]; then
        echo "Error: Prompt file not found: $PROMPT_FILE" >&2
        exit 1
    fi
    PROMPT=$(cat "$PROMPT_FILE")
elif [[ -n "$PROMPT_ARGS" ]]; then
    PROMPT="$PROMPT_ARGS"
elif [[ ! -t 0 ]]; then
    PROMPT=$(cat)
else
    echo "Error: No prompt provided. Use -f, arguments, or pipe stdin." >&2
    exit 1
fi

if [[ -z "$PROMPT" ]]; then
    echo "Error: Empty prompt." >&2
    exit 1
fi

# Validate working directory
if [[ ! -d "$WORKDIR" ]]; then
    echo "Error: Working directory not found: $WORKDIR" >&2
    exit 1
fi

# Build cursor agent command arguments
CURSOR_ARGS=(
    "--print"
    "--trust"
    "--workspace" "$WORKDIR"
    "--model" "$MODEL"
)

# Review/plan mode: read-only analysis without file modifications
if [[ "$REVIEW_MODE" == true ]]; then
    CURSOR_ARGS+=("--mode" "plan")
else
    # Default: yolo mode (auto-approve all tool calls)
    CURSOR_ARGS+=("--yolo")
fi

# Optional sandbox override
if [[ -n "$SANDBOX" ]]; then
    CURSOR_ARGS+=("--sandbox" "$SANDBOX")
fi

echo "=== Cursor UI Agent Starting ===" >&2
echo "Model: $MODEL | Dir: $WORKDIR | Timeout: ${TIMEOUT}s | Review: $REVIEW_MODE" >&2
echo "---" >&2

# Execute cursor agent CLI with timeout
timeout "$TIMEOUT" agent "${CURSOR_ARGS[@]}" "$PROMPT"
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 124 ]]; then
    echo "Error: Cursor Agent execution timed out after ${TIMEOUT}s" >&2
    exit 124
fi

exit $EXIT_CODE
