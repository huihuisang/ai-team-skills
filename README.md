# AI Team Skills for Claude Code

中文 | [English](README_EN.md)

将 Gemini CLI、Codex CLI 和 **Cursor CLI** 集成为 Claude Code 的 skill，让 Claude Code 能够：

- 委派 UI 设计任务给 **Gemini 3.1 Pro**（gemini-agent / cursor-ui-agent）
- 委派代码编写/审查任务给 **GPT-5.3 Codex**（codex-agent / cursor-code-agent）
- 编排多 Agent 协作流水线，**自动检测可用工具并降级路由**（ai-team）

## 架构

```
Claude Code (编排者/大脑)
    ├── ai-team skill          → 多 Agent 流水线编排（自动工具检测）
    ├── gemini-agent skill     → gemini-cli  → UI/前端设计
    ├── codex-agent skill      → codex-cli   → 代码编写/审查
    ├── cursor-ui-agent skill  → cursor-cli  → UI/前端设计（Gemini 3.1 Pro）
    ├── cursor-code-agent skill→ cursor-cli  → 代码编写/审查（GPT-5.3 Codex）
    └── agents/                → Worker Agent 定义（ai-team 流水线所需）
        ├── codex-worker.md        → Codex Worker subagent
        ├── gemini-worker.md       → Gemini Worker subagent
        ├── cursor-code-worker.md  → Cursor Code Worker subagent
        └── cursor-ui-worker.md    → Cursor UI Worker subagent
```

## Skills

### ai-team

多 Agent 协作流水线，自动检测已安装的 CLI 工具并按优先级路由任务。

```
/ai-team <复杂任务描述>
```

| 工具检测结果 | UI 任务路由 | 代码任务路由 |
|------------|------------|------------|
| Gemini CLI 已安装 | gemini-worker | — |
| Codex CLI 已安装 | — | codex-worker |
| 只有 Cursor CLI | cursor-ui-worker | cursor-code-worker |
| 都没有 | Claude 自己处理 | Claude 自己处理 |

适用于全栈开发、大型重构、UI→实现联动等需要多 agent 协作的场景。

---

### gemini-agent

Gemini (gemini-3-pro-preview) AI 代理 - UI 设计与前端开发专家。

```
/gemini-agent <UI 设计描述>
```

- 包装脚本：`gemini-agent/scripts/gemini-run.sh`（Linux/macOS）、`gemini-run.ps1`（Windows）
- Prompt 模板：`gemini-agent/references/prompt-templates.md`

---

### codex-agent

Codex (gpt-5.3-codex) AI 代理 - 代码编写与实现专家。支持 exec（编写）和 review（审查）两种模式。

```
/codex-agent <代码任务描述>
```

- 包装脚本：`codex-agent/scripts/codex-run.sh`（Linux/macOS）、`codex-run.ps1`（Windows）
- Prompt 模板：`codex-agent/references/prompt-templates.md`
- 支持 review 模式：`-r --uncommitted` 审查未提交变更

---

### cursor-ui-agent ✨ 新增

通过 Cursor CLI 调用 **Gemini 3.1 Pro** 完成 UI 设计任务。无需安装 Gemini CLI，只需要 Cursor。

```
/cursor-ui-agent <UI 设计描述>
```

- 默认模型：`gemini-3.1-pro`（可通过 `--model` 切换）
- 包装脚本：`cursor-ui-agent/scripts/cursor-run.sh`（Linux/macOS）、`cursor-run.ps1`（Windows）
- Prompt 模板：`cursor-ui-agent/references/prompt-templates.md`

---

### cursor-code-agent ✨ 新增

通过 Cursor CLI 调用 **GPT-5.3 Codex** 完成代码实现任务。无需安装 Codex CLI，只需要 Cursor。

```
/cursor-code-agent <代码任务描述>
```

- 默认模型：`gpt-5.3-codex`（可通过 `--model` 切换为 `gpt-5.3-codex-high` 等）
- 支持 review 模式：`-r` 切换为只读分析模式（`--mode plan`）
- 包装脚本：`cursor-code-agent/scripts/cursor-run.sh`（Linux/macOS）、`cursor-run.ps1`（Windows）
- Prompt 模板：`cursor-code-agent/references/prompt-templates.md`

---

## 协作模式

### 单 Agent 委派

```
Claude Code 分析任务 → 构建 prompt → 调用对应 CLI → 收集结果
```

### 多 Agent 流水线（ai-team）

```
模式 A: UI → 实现（串行）
  [UI Worker] 设计 UI → Claude 审查 → [代码 Worker] 实现 → 测试

模式 B: 审查 → 修复（串行）
  [代码 Worker review] 审查 → Claude 确认 → [代码 Worker] 修复 → 测试

模式 C: 多模块并行
  [代码 Worker-1] 模块 A ─┐
  [代码 Worker-2] 模块 B ─┤→ Claude 整合 → 集成测试
  [UI Worker]     UI    ─┘

UI Worker   = gemini-worker 或 cursor-ui-worker（自动选择）
代码 Worker = codex-worker  或 cursor-code-worker（自动选择）
```

---

## 前置要求

以下工具**至少安装一组**即可使用：

| 方案 | 需要安装 | 说明 |
|------|---------|------|
| **推荐：仅 Cursor** | [Cursor](https://cursor.com) | 一个工具搞定 UI + 代码，最简单 |
| 原生 Gemini + Codex | [Gemini CLI](https://github.com/google-gemini/gemini-cli) + [Codex CLI](https://github.com/openai/codex) | 直连各自 CLI，性能最优 |
| 混合 | 任意组合 | ai-team 自动检测路由 |

所有方案均需要：
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 已安装

---

## 安装

### 方案一：完整安装（推荐）

包含所有 skill + worker agent，支持全部功能和 ai-team 流水线。

**Linux / macOS**：
```bash
# 克隆仓库
git clone https://github.com/your-repo/ai-team-skills.git
cd ai-team-skills

# 安装全部 skills（含 cursor agent）
cp -r ai-team gemini-agent codex-agent cursor-ui-agent cursor-code-agent ~/.claude/skills/

# 安装 Worker Agent 定义（ai-team 流水线必须）
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
```

**Windows (PowerShell)**：
```powershell
# 安装全部 skills（含 cursor agent）
@("ai-team","gemini-agent","codex-agent","cursor-ui-agent","cursor-code-agent") | ForEach-Object {
    Copy-Item -Recurse $_ "$env:USERPROFILE\.claude\skills\"
}

# 安装 Worker Agent 定义
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\agents" | Out-Null
Copy-Item agents\*.md "$env:USERPROFILE\.claude\agents\"
```

---

### 方案二：仅 Cursor Agent（最简安装）

只有 Cursor CLI，不需要 Gemini/Codex CLI：

**Linux / macOS**：
```bash
cp -r ai-team cursor-ui-agent cursor-code-agent ~/.claude/skills/
mkdir -p ~/.claude/agents
cp agents/cursor-ui-worker.md agents/cursor-code-worker.md ~/.claude/agents/
```

**Windows (PowerShell)**：
```powershell
@("ai-team","cursor-ui-agent","cursor-code-agent") | ForEach-Object {
    Copy-Item -Recurse $_ "$env:USERPROFILE\.claude\skills\"
}
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\agents" | Out-Null
Copy-Item agents\cursor-ui-worker.md, agents\cursor-code-worker.md "$env:USERPROFILE\.claude\agents\"
```

---

### 方案三：原有用户升级（新增 Cursor 支持）

已安装 gemini-agent 和 codex-agent，仅追加 cursor agent：

**Linux / macOS**：
```bash
# 追加 cursor agent skills
cp -r cursor-ui-agent cursor-code-agent ~/.claude/skills/

# 追加 cursor worker agent
cp agents/cursor-ui-worker.md agents/cursor-code-worker.md ~/.claude/agents/

# 更新 ai-team skill（支持工具检测和降级路由）
cp -r ai-team ~/.claude/skills/
```

**Windows (PowerShell)**：
```powershell
@("cursor-ui-agent","cursor-code-agent","ai-team") | ForEach-Object {
    Copy-Item -Recurse -Force $_ "$env:USERPROFILE\.claude\skills\"
}
Copy-Item agents\cursor-ui-worker.md, agents\cursor-code-worker.md "$env:USERPROFILE\.claude\agents\"
```

---

> **重要**：使用 ai-team 流水线模式时，必须安装 `agents/` 目录下对应的 Worker Agent 定义文件到 `~/.claude/agents/`。
> Worker Agent 定义了 `codex-worker`、`gemini-worker`、`cursor-code-worker`、`cursor-ui-worker` 四个自定义 subagent，是 Team 模式正常运行的前提。

---

## 验证安装

安装完成后，可以用以下命令验证：

```bash
# 检查 skill 是否就位
ls ~/.claude/skills/

# 检查 worker agent 是否就位
ls ~/.claude/agents/

# 检查 cursor CLI 是否可用
agent --version

# 在 Claude Code 中测试
/cursor-ui-agent 设计一个简单的登录页面
/cursor-code-agent 为登录页面实现表单验证逻辑
```

---

## License

MIT
