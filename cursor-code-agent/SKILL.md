---
name: cursor-code-agent
description: "Cursor Agent (gpt-5.3-codex) 代码实现专家。通过 Cursor CLI 调用 GPT-5.3 Codex 模型完成代码编写、修复、重构、审查任务。使用 /cursor-code-agent <描述> 委派代码任务。支持 review 只读分析模式。无 Codex CLI 时的首选替代方案。"
---

# Cursor Code Agent - GPT-5.3 Codex 代码实现专家

通过 Cursor Agent CLI 调用 GPT-5.3 Codex 模型，完成代码编写、修复、重构和审查任务，由 Claude Code 编排和审查。

## 用法

```
/cursor-code-agent <代码任务描述>
```

也可由 Claude Code 在分析任务后自动委派（当任务涉及代码编写/实现/修复/重构/测试/审查时，且 Codex CLI 不可用时）。

## 执行步骤

1. **判断当前平台**：检查运行环境是 Linux/macOS 还是 Windows
   - Linux/macOS → 使用 `cursor-run.sh`
   - Windows → 使用 `cursor-run.ps1`（必须通过 `powershell.exe -ExecutionPolicy Bypass -File` 调用）
2. **准备 prompt 文件**：将任务描述写入临时文件（推荐使用 `-f` / `-File` 参数，避免 shell 转义问题）
3. **选择模式**：代码编写用默认模式（--yolo），代码审查用 review 模式（-r）
4. **执行脚本**：调用对应平台的包装脚本
5. **读取结果**：通过 `-o` / `-Output` 指定的输出文件获取执行结果

## 执行方式

**Linux / macOS (Bash)**：
```bash
# 标准执行（默认 yolo 模式，自动批准所有操作）
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh -f /tmp/cursor-code-prompt.txt -d <工作目录>

# 将结果写入文件（流水线模式）
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh -f /tmp/cursor-code-prompt.txt -o /tmp/cursor-code-result.txt -d <工作目录>

# 只读代码分析/审查（plan 模式）
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh -r -f /tmp/review-prompt.txt -d <工作目录> -o /tmp/review-result.txt

# 切换到高推理力模型
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh -f /tmp/prompt.txt --model gpt-5.3-codex-high -d <工作目录>
```

**Windows（重要：必须使用 powershell.exe 调用 .ps1 脚本）**：
```bash
# 标准执行
powershell.exe -ExecutionPolicy Bypass -File ~/.claude/skills/cursor-code-agent/scripts/cursor-run.ps1 -File /tmp/cursor-code-prompt.txt -Dir <工作目录>

# 只读代码审查
powershell.exe -ExecutionPolicy Bypass -File ~/.claude/skills/cursor-code-agent/scripts/cursor-run.ps1 -Review -File /tmp/review-prompt.txt -Dir <工作目录> -Output /tmp/review-result.txt
```

### 脚本参数

```
cursor-run.sh / cursor-run.ps1 [OPTIONS] [prompt...]

Bash:                                PowerShell:
  --model <model>                      -Model <model>         (默认 gpt-5.3-codex)
  -d, --dir <directory>                -Dir <directory>
  -t, --timeout <seconds>              -Timeout <seconds>     (默认 900s)
  -f, --file <file>                    -File <file>
  -r, --review                         -Review                (只读 plan 模式)
  -s, --sandbox <mode>                 -Sandbox <mode>        (enabled|disabled)
  -o, --output <file>                  -Output <file>
```

## Cursor Agent CLI 参数说明

| 功能 | 参数 | 说明 |
|------|------|------|
| 打印模式（脚本用） | `--print` | 输出到控制台，不启动交互界面 |
| 信任工作区 | `--trust` | 不弹出工作区信任确认（headless 必须） |
| 自动批准 | `--yolo` | 自动批准所有工具调用（类似 codex --full-auto） |
| 只读分析 | `--mode plan` | 只分析和规划，不修改文件（类似 codex read-only） |
| 工作目录 | `--workspace <path>` | 指定工作目录 |
| 模型选择 | `--model <model>` | 指定模型（如 gpt-5.3-codex, gpt-5.3-codex-high） |
| 沙箱控制 | `--sandbox enabled\|disabled` | 控制沙箱执行环境 |

## 可选模型推荐

| 模型 | 适用场景 |
|------|---------|
| `gpt-5.3-codex` | 通用代码任务（默认，速度/质量平衡） |
| `gpt-5.3-codex-high` | 复杂逻辑、架构设计 |
| `gpt-5.3-codex-fast` | 快速迭代、简单修复 |
| `gpt-5.3-codex-xhigh` | 最高推理深度（耗时较长） |

## 两种执行模式

### 默认模式 - 代码编写/修复

用于代码编写、功能实现、bug 修复、重构等需要修改文件的任务。

```bash
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh \
  -f /tmp/prompt.txt \
  -o /tmp/result.txt \
  -d <工作目录>
```

### review 模式 - 代码分析/审查（只读）

用于代码审查、安全检查、质量分析等不需要修改文件的任务（`--mode plan`）。

```bash
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh \
  -r \
  -f /tmp/review-prompt.txt \
  -o /tmp/review-result.txt \
  -d <工作目录>
```

## Prompt 构建指南

将用户需求转化为 Cursor Agent 友好的 prompt 时：

1. **明确任务** - 清晰描述要实现的功能或修复的问题
2. **提供上下文** - 相关文件路径、现有代码结构、依赖关系
3. **技术约束** - 语言版本、框架要求、编码规范
4. **验收标准** - 期望的输出、测试要求
5. **文件操作** - 明确指出要创建/修改的文件路径

参考 `references/prompt-templates.md` 获取完整模板。

## 输出捕获

```bash
# 代码实现（结果写入文件）
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh \
  -f /tmp/cursor-code-prompt.txt \
  -o /tmp/cursor-code-result.txt \
  -d ./project

# 代码审查（同样支持输出文件）
bash ~/.claude/skills/cursor-code-agent/scripts/cursor-run.sh \
  -r \
  -f /tmp/review-prompt.txt \
  -o /tmp/cursor-review-result.txt \
  -d ./project
```

Claude 随后读取输出文件获取执行结果。

## 与 codex-agent 的关系

cursor-code-agent 是 codex-agent 的替代方案：
- **codex-agent**: 直接调用 Codex CLI（需要安装 OpenAI Codex CLI）
- **cursor-code-agent**: 通过 Cursor Agent CLI 调用 GPT-5.3 Codex（只需安装 Cursor）

**优先级**：`codex-agent`（如 Codex CLI 已安装）> `cursor-code-agent`（仅需 Cursor CLI）

## 并行任务拆分

**Cursor Agent 运行时间较长（通常 5-15 分钟），可通过任务拆分 + 并行执行提升效率。**

1. **分析任务** - 收到用户请求后，先分析是否可以拆分为多个独立子任务
2. **并行执行** - 使用 Bash 工具的 `run_in_background: true` 模式启动多个后台任务
3. **汇总审查** - 所有子任务完成后，Claude 审查并整合结果

## 任务路由

当用户请求包含以下关键词时，且 Codex CLI 不可用时，路由到 cursor-code-agent：
- 实现、编写、修复、重构、测试、代码、功能、API、后端、数据库、bug
- review、审查、检查代码、代码质量
