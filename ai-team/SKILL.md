---
name: ai-team
description: "AI 团队协作流水线。自动编排 Claude(Lead) + Codex/Cursor-Code(代码) + Gemini/Cursor-UI(UI) 多 Agent 协作。自动检测可用工具，支持 Gemini CLI、Codex CLI、Cursor CLI 降级路由。使用 /ai-team <任务描述> 启动团队协作。"
---

# AI Team - 多 Agent 协作流水线

自动编排 Claude (Team Lead) + 代码 Worker + UI Worker 的多 Agent 协作流水线。
**自动检测已安装的 AI CLI 工具，按优先级路由任务**。适用于任何项目。

## 用法

```
/ai-team <复杂任务描述>
/team <复杂任务描述>
```

## 何时使用

**使用 AI Team**（需要多 agent 协作）：
- 全栈功能开发（UI + 后端 + 测试）
- 大型重构（多文件、多模块并行）
- UI 设计 + 逻辑实现的联动任务
- 代码审查 + 修复的流水线

**不使用 AI Team**（单 agent 即可）：
- 单文件修改 → `/codex-agent` 或 `/cursor-code-agent`
- 纯 UI 任务 → `/gemini-agent` 或 `/cursor-ui-agent`
- 简单 bug 修复 → Claude 自己处理

## 工具检测（Phase 0）

**在启动任何 Worker 之前，先检测可用工具**：

```bash
# 检测三个 CLI 工具是否已安装
command -v gemini >/dev/null 2>&1 && echo "gemini: available" || echo "gemini: not found"
command -v codex  >/dev/null 2>&1 && echo "codex: available"  || echo "codex: not found"
command -v agent  >/dev/null 2>&1 && echo "cursor: available" || echo "cursor: not found"
```

### UI 设计任务路由（按优先级）

| 优先级 | 条件 | 使用的 Worker |
|--------|------|--------------|
| 1st | `gemini` CLI 可用 | `gemini-worker`（Gemini CLI 直连） |
| 2nd | `agent` CLI 可用 | `cursor-ui-worker`（Cursor + gemini-3.1-pro） |
| 3rd | 两者都不可用 | Claude 自己处理 UI 任务 |

### 代码实现任务路由（按优先级）

| 优先级 | 条件 | 使用的 Worker |
|--------|------|--------------|
| 1st | `codex` CLI 可用 | `codex-worker`（Codex CLI 直连） |
| 2nd | `agent` CLI 可用 | `cursor-code-worker`（Cursor + gpt-5.3-codex） |
| 3rd | 两者都不可用 | Claude 自己处理代码任务 |

## 团队角色

| 角色 | Agent 选项 | 职责 |
|------|-----------|------|
| Team Lead | Claude (你自己) | 任务拆分、分配、审查、整合、质量把控 |
| 代码 Worker | `codex-worker` 或 `cursor-code-worker` | 代码编写、修复、审查、测试 |
| UI Worker | `gemini-worker` 或 `cursor-ui-worker` | UI 设计、前端组件、样式 |

## 执行流程

### Phase 0: 工具检测

```bash
# Run tool detection before any other step
command -v gemini >/dev/null 2>&1 && HAS_GEMINI=true || HAS_GEMINI=false
command -v codex  >/dev/null 2>&1 && HAS_CODEX=true  || HAS_CODEX=false
command -v agent  >/dev/null 2>&1 && HAS_CURSOR=true  || HAS_CURSOR=false
```

根据检测结果决定：
- UI Worker: `gemini-worker` (if HAS_GEMINI) → `cursor-ui-worker` (if HAS_CURSOR) → Claude自处理
- 代码 Worker: `codex-worker` (if HAS_CODEX) → `cursor-code-worker` (if HAS_CURSOR) → Claude自处理

### Phase 1: 分析与拆分

1. 分析用户任务，识别子任务类型：
   - 前端/UI → UI Worker（路由见上）
   - 后端/逻辑/测试 → 代码 Worker（路由见上）
   - 全栈 → 两者协作
2. 确定依赖关系（独立任务并行，有依赖的串行）
3. 识别项目上下文（工作目录、技术栈、测试命令）

### Phase 2: 创建团队

```
1. TeamCreate → "ai-team-{timestamp}"
2. TaskCreate → 创建所有子任务（含依赖）
3. Task tool → 启动 worker（subagent_type: 根据路由决策选择）
4. TaskUpdate → 分配任务
5. SendMessage → 发送项目上下文
```

### Phase 3: 执行与监控

- Worker 自主执行，完成后通过 SendMessage 汇报
- Team Lead 审查结果
- 依赖任务解锁后分配给下一个 worker
- 处理 worker 间的上下文传递

### Phase 4: 整合与交付

- 所有任务完成 → 最终审查
- 运行测试验证
- 向用户汇报结果
- shutdown_request 关闭 worker → TeamDelete 清理

## 启动 Worker 模板

### codex-worker（Codex CLI 可用时）

```
Task tool:
  subagent_type: "codex-worker"
  team_name: "{team_name}"
  name: "codex-worker"
  prompt: |
    你是 AI Team 的 Codex 工作者。
    团队: {team_name}
    你的名字: codex-worker

    项目工作目录: {workdir}
    项目信息: {project_context}

    请查看 TaskList 获取分配给你的任务，然后开始工作。
    完成后用 TaskUpdate 标记 completed，
    并通过 SendMessage 向 team-lead 汇报。
```

### cursor-code-worker（仅 Cursor CLI 可用时）

```
Task tool:
  subagent_type: "cursor-code-worker"
  team_name: "{team_name}"
  name: "cursor-code-worker"
  prompt: |
    你是 AI Team 的 Cursor Code 工作者（GPT-5.3 Codex 模型）。
    团队: {team_name}
    你的名字: cursor-code-worker

    项目工作目录: {workdir}
    项目信息: {project_context}

    请查看 TaskList 获取分配给你的任务，然后开始工作。
    完成后用 TaskUpdate 标记 completed，
    并通过 SendMessage 向 team-lead 汇报。
```

### gemini-worker（Gemini CLI 可用时）

```
Task tool:
  subagent_type: "gemini-worker"
  ...
```

### cursor-ui-worker（仅 Cursor CLI 可用时）

```
Task tool:
  subagent_type: "cursor-ui-worker"
  team_name: "{team_name}"
  name: "cursor-ui-worker"
  prompt: |
    你是 AI Team 的 Cursor UI 工作者（Gemini 3.1 Pro 模型）。
    团队: {team_name}
    你的名字: cursor-ui-worker

    项目工作目录: {workdir}
    项目信息: {project_context}

    请查看 TaskList 获取分配给你的任务，然后开始工作。
    完成后用 TaskUpdate 标记 completed，
    并通过 SendMessage 向 team-lead 汇报。
```

## 上下文传递

当一个 worker 的输出需要传递给另一个 worker 时：

1. **文件路径** - 前序 worker 生成的文件已在工作目录中，后续 worker 可直接读取
2. **摘要传递** - Team Lead 在 SendMessage 中包含前序输出的关键信息
3. **任务描述** - 在后续任务的 description 中包含前序的设计决策和接口定义

## 错误处理

- Worker 失败 → 分析原因，修改 prompt 后重新分配
- CLI 超时 → 拆分为更小的子任务
- 依赖冲突 → Team Lead 手动解决
- Worker 无响应 → shutdown_request 后重启

## 流水线模式

### 模式 A: UI → 实现（串行）
```
[UI Worker] 设计 UI → Team Lead 审查 → [代码 Worker] 实现逻辑 → 测试

UI Worker 选择:   gemini-worker 或 cursor-ui-worker
代码 Worker 选择: codex-worker 或 cursor-code-worker
```

### 模式 B: 审查 → 修复（串行）
```
[代码 Worker review 模式] 审查代码 → Team Lead 确认 → [代码 Worker] 修复问题 → 测试
```

### 模式 C: 多模块并行
```
[代码 Worker-1] 实现模块 A ─┐
[代码 Worker-2] 实现模块 B ─┤→ Team Lead 整合 → 集成测试
[UI Worker]     设计 UI    ─┘
```

## 工具组合示例

### 场景 1：只有 Cursor CLI
```
检测结果: gemini ✗ | codex ✗ | cursor ✓
UI 任务  → cursor-ui-worker   (Gemini 3.1 Pro)
代码任务 → cursor-code-worker (GPT-5.3 Codex)
```

### 场景 2：只有 Gemini + Codex
```
检测结果: gemini ✓ | codex ✓ | cursor ✓/✗
UI 任务  → gemini-worker  (原生 Gemini CLI)
代码任务 → codex-worker   (原生 Codex CLI)
```

### 场景 3：全部安装
```
检测结果: gemini ✓ | codex ✓ | cursor ✓
UI 任务  → gemini-worker  (优先原生 CLI)
代码任务 → codex-worker   (优先原生 CLI)
```

### 场景 4：什么都没有
```
检测结果: gemini ✗ | codex ✗ | cursor ✗
所有任务 → Claude 自己处理（告知用户安装建议）
```
