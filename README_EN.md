# AI Team Skills for Claude Code

[中文](README.md) | English

Integrate Gemini CLI, Codex CLI, and **Cursor CLI** as Claude Code skills, enabling Claude Code to:

- Delegate UI design tasks to **Gemini 3.1 Pro** (gemini-agent / cursor-ui-agent)
- Delegate code writing/review tasks to **GPT-5.3 Codex** (codex-agent / cursor-code-agent)
- Orchestrate multi-agent collaboration pipelines with **automatic tool detection and fallback routing** (ai-team)

## Architecture

```
Claude Code (Orchestrator)
    ├── ai-team skill           → Multi-agent pipeline (auto tool detection)
    ├── gemini-agent skill      → gemini-cli  → UI/Frontend design
    ├── codex-agent skill       → codex-cli   → Code writing/review
    ├── cursor-ui-agent skill   → cursor-cli  → UI/Frontend design (Gemini 3.1 Pro)
    ├── cursor-code-agent skill → cursor-cli  → Code writing/review (GPT-5.3 Codex)
    └── agents/                 → Worker Agent definitions (required for ai-team)
        ├── codex-worker.md         → Codex Worker subagent
        ├── gemini-worker.md        → Gemini Worker subagent
        ├── cursor-code-worker.md   → Cursor Code Worker subagent
        └── cursor-ui-worker.md     → Cursor UI Worker subagent
```

## Skills

### ai-team

Multi-agent collaboration pipeline that automatically detects installed CLI tools and routes tasks by priority.

```
/ai-team <complex task description>
```

| Tool Detection | UI Task Routes To | Code Task Routes To |
|---------------|------------------|---------------------|
| Gemini CLI installed | gemini-worker | — |
| Codex CLI installed | — | codex-worker |
| Only Cursor CLI | cursor-ui-worker | cursor-code-worker |
| None available | Claude handles it | Claude handles it |

Ideal for full-stack development, large-scale refactoring, and UI→implementation workflows.

---

### gemini-agent

Gemini (gemini-3-pro-preview) AI agent — UI design and frontend development expert.

```
/gemini-agent <UI design description>
```

- Wrapper scripts: `gemini-agent/scripts/gemini-run.sh` (Linux/macOS), `gemini-run.ps1` (Windows)
- Prompt templates: `gemini-agent/references/prompt-templates.md`

---

### codex-agent

Codex (gpt-5.3-codex) AI agent — code writing and implementation expert. Supports exec (write) and review (audit) modes.

```
/codex-agent <code task description>
```

- Wrapper scripts: `codex-agent/scripts/codex-run.sh` (Linux/macOS), `codex-run.ps1` (Windows)
- Prompt templates: `codex-agent/references/prompt-templates.md`
- Review mode: `-r --uncommitted` to audit uncommitted changes

---

### cursor-ui-agent ✨ New

Calls **Gemini 3.1 Pro** via Cursor CLI for UI design tasks. No Gemini CLI required — only Cursor needed.

```
/cursor-ui-agent <UI design description>
```

- Default model: `gemini-3.1-pro` (override with `--model`)
- Wrapper scripts: `cursor-ui-agent/scripts/cursor-run.sh` (Linux/macOS), `cursor-run.ps1` (Windows)
- Prompt templates: `cursor-ui-agent/references/prompt-templates.md`

---

### cursor-code-agent ✨ New

Calls **GPT-5.3 Codex** via Cursor CLI for code implementation tasks. No Codex CLI required — only Cursor needed.

```
/cursor-code-agent <code task description>
```

- Default model: `gpt-5.3-codex` (override with `--model`, e.g. `gpt-5.3-codex-high`)
- Review mode: `-r` switches to read-only plan mode (`--mode plan`)
- Wrapper scripts: `cursor-code-agent/scripts/cursor-run.sh` (Linux/macOS), `cursor-run.ps1` (Windows)
- Prompt templates: `cursor-code-agent/references/prompt-templates.md`

---

## Collaboration Modes

### Single Agent Delegation

```
Claude Code analyzes task → builds prompt → calls CLI → collects results
```

### Multi-Agent Pipeline (ai-team)

```
Mode A: UI → Implementation (sequential)
  [UI Worker] designs UI → Claude reviews → [Code Worker] implements → Tests

Mode B: Review → Fix (sequential)
  [Code Worker review] audits code → Claude confirms → [Code Worker] fixes → Tests

Mode C: Multi-module parallel
  [Code Worker 1] Module A ─┐
  [Code Worker 2] Module B  ─┤→ Claude integrates → Integration tests
  [UI Worker]     UI        ─┘

UI Worker   = gemini-worker or cursor-ui-worker   (auto-selected)
Code Worker = codex-worker  or cursor-code-worker (auto-selected)
```

---

## Prerequisites

**Install at least one of the following combinations:**

| Option | What to Install | Notes |
|--------|----------------|-------|
| **Recommended: Cursor only** | [Cursor](https://cursor.com) | One tool for both UI + code, simplest setup |
| Native Gemini + Codex | [Gemini CLI](https://github.com/google-gemini/gemini-cli) + [Codex CLI](https://github.com/openai/codex) | Direct CLI access, best performance |
| Mixed | Any combination | ai-team auto-detects and routes |

All options also require:
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed

---

## Installation

### Option 1: Full Install (Recommended)

Installs all skills + worker agents, enabling all features including the ai-team pipeline.

**Linux / macOS**:
```bash
# Clone the repository
git clone https://github.com/your-repo/ai-team-skills.git
cd ai-team-skills

# Install all skills (including cursor agents)
cp -r ai-team gemini-agent codex-agent cursor-ui-agent cursor-code-agent ~/.claude/skills/

# Install Worker Agent definitions (required for ai-team pipeline)
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
```

**Windows (PowerShell)**:
```powershell
# Install all skills (including cursor agents)
@("ai-team","gemini-agent","codex-agent","cursor-ui-agent","cursor-code-agent") | ForEach-Object {
    Copy-Item -Recurse $_ "$env:USERPROFILE\.claude\skills\"
}

# Install Worker Agent definitions
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\agents" | Out-Null
Copy-Item agents\*.md "$env:USERPROFILE\.claude\agents\"
```

---

### Option 2: Cursor Only (Minimal Install)

Only Cursor CLI available — no Gemini or Codex CLI needed:

**Linux / macOS**:
```bash
cp -r ai-team cursor-ui-agent cursor-code-agent ~/.claude/skills/
mkdir -p ~/.claude/agents
cp agents/cursor-ui-worker.md agents/cursor-code-worker.md ~/.claude/agents/
```

**Windows (PowerShell)**:
```powershell
@("ai-team","cursor-ui-agent","cursor-code-agent") | ForEach-Object {
    Copy-Item -Recurse $_ "$env:USERPROFILE\.claude\skills\"
}
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\agents" | Out-Null
Copy-Item agents\cursor-ui-worker.md, agents\cursor-code-worker.md "$env:USERPROFILE\.claude\agents\"
```

---

### Option 3: Upgrade Existing Install (Add Cursor Support)

Already have gemini-agent and codex-agent — just add cursor agent support:

**Linux / macOS**:
```bash
# Add cursor agent skills
cp -r cursor-ui-agent cursor-code-agent ~/.claude/skills/

# Add cursor worker agents
cp agents/cursor-ui-worker.md agents/cursor-code-worker.md ~/.claude/agents/

# Update ai-team skill (adds tool detection and fallback routing)
cp -r ai-team ~/.claude/skills/
```

**Windows (PowerShell)**:
```powershell
@("cursor-ui-agent","cursor-code-agent","ai-team") | ForEach-Object {
    Copy-Item -Recurse -Force $_ "$env:USERPROFILE\.claude\skills\"
}
Copy-Item agents\cursor-ui-worker.md, agents\cursor-code-worker.md "$env:USERPROFILE\.claude\agents\"
```

---

> **Important**: To use ai-team pipeline mode, you must install the corresponding Worker Agent definition files from `agents/` to `~/.claude/agents/`.
> These files define the `codex-worker`, `gemini-worker`, `cursor-code-worker`, and `cursor-ui-worker` custom subagents required for Team mode to function.

---

## Verify Installation

After installing, verify everything is in place:

```bash
# Check skills are installed
ls ~/.claude/skills/

# Check worker agents are installed
ls ~/.claude/agents/

# Check cursor CLI is available
agent --version

# Test in Claude Code
/cursor-ui-agent Design a simple login page
/cursor-code-agent Implement form validation for the login page
```

---

## License

MIT
