---
name: cursor-ui-agent
description: "Cursor Agent (gemini-3.1-pro) UI 设计专家。通过 Cursor CLI 调用 Gemini 3.1 Pro 模型完成 UI 设计与前端开发任务。触发条件：UI 设计、前端组件、页面布局、视觉设计、样式美化。使用 /cursor-ui-agent <描述> 委派 UI 设计任务。无 Gemini CLI 时的首选替代方案。"
---

# Cursor UI Agent - Gemini 3.1 Pro UI 设计专家

通过 Cursor Agent CLI 调用 Gemini 3.1 Pro 模型，完成 UI 设计与前端开发任务，由 Claude Code 编排和审查。

## 用法

```
/cursor-ui-agent <UI 设计描述>
```

也可由 Claude Code 在分析任务后自动委派（当任务涉及 UI/设计/组件/页面/布局/样式时，且 Gemini CLI 不可用时）。

## 执行步骤

1. **判断当前平台**：检查运行环境是 Linux/macOS 还是 Windows
   - Linux/macOS → 使用 `cursor-run.sh`
   - Windows → 使用 `cursor-run.ps1`（必须通过 `powershell.exe -ExecutionPolicy Bypass -File` 调用）
2. **准备 prompt 文件**：将 UI 设计描述写入临时文件（推荐使用 `-f` / `-File` 参数）
3. **执行脚本**：调用对应平台的包装脚本
4. **检查生成的文件**：通过 git status 或 ls 查看 Cursor Agent 生成了哪些文件

## 执行方式

**推荐：使用 `-f` 文件模式传递 prompt（避免 shell 转义问题）**

**Linux / macOS (Bash)**：
```bash
bash ~/.claude/skills/cursor-ui-agent/scripts/cursor-run.sh -f /tmp/cursor-ui-prompt.txt -d <工作目录>
```

**Windows（必须使用 powershell.exe 调用 .ps1 脚本）**：
```bash
powershell.exe -ExecutionPolicy Bypass -File ~/.claude/skills/cursor-ui-agent/scripts/cursor-run.ps1 -File /tmp/cursor-ui-prompt.txt -Dir <工作目录>
```

**切换模型（可选）**：
```bash
# 使用更快的 Gemini 3 Flash 模型
bash ~/.claude/skills/cursor-ui-agent/scripts/cursor-run.sh -f /tmp/prompt.txt --model gemini-3-flash -d <工作目录>

# 使用 Gemini 3 Pro（上一代）
bash ~/.claude/skills/cursor-ui-agent/scripts/cursor-run.sh -f /tmp/prompt.txt --model gemini-3-pro -d <工作目录>
```

### 脚本参数

```
cursor-run.sh / cursor-run.ps1 [OPTIONS] [prompt...]

Bash:                                PowerShell:
  --model <model>                      -Model <model>         (默认 gemini-3.1-pro)
  -d, --dir <directory>                -Dir <directory>
  -t, --timeout <seconds>              -Timeout <seconds>     (默认 300s)
  -f, --file <file>                    -File <file>
  -r, --review                         -Review                (只读分析模式)
  -s, --sandbox <mode>                 -Sandbox <mode>        (enabled|disabled)
```

## Cursor Agent CLI 参数说明

| 功能 | 参数 | 说明 |
|------|------|------|
| 打印模式（脚本用） | `--print` | 输出到控制台，不启动交互界面 |
| 信任工作区 | `--trust` | 不弹出工作区信任确认（headless 必须） |
| 自动批准 | `--yolo` | 自动批准所有工具调用（类似 gemini -y） |
| 只读分析 | `--mode plan` | 只分析和规划，不修改文件 |
| 工作目录 | `--workspace <path>` | 指定工作目录 |
| 模型选择 | `--model <model>` | 指定模型（如 gemini-3.1-pro） |
| 沙箱控制 | `--sandbox enabled\|disabled` | 控制沙箱执行环境 |

## Prompt 构建指南

将用户需求转化为 Cursor Agent 友好的 prompt 时，遵循以下结构：

1. **角色设定** - 明确要求使用 Gemini 3.1 Pro 的设计能力，例如：「你是一个使用 Gemini 3.1 Pro 的顶级 UI 设计师和前端开发专家。」
2. **任务描述** - 清晰描述要生成的 UI
3. **技术栈** - 明确框架（React/Vue/HTML）和样式方案（Tailwind/CSS）
4. **代码规范** - 语义化 HTML、可访问性、响应式、TypeScript
5. **设计风格** - 视觉要求（现代简洁、间距圆角、微交互）
6. **输出要求** - 直接生成代码，写入指定文件路径

参考 `references/prompt-templates.md` 获取完整模板。

## 输出处理

Cursor Agent 生成的文件直接写入工作目录。Claude Code 应：
1. 检查 Cursor Agent 生成了哪些文件（通过 git status 或 ls）
2. 读取并审查生成的代码质量
3. 必要时进行微调和修正

## 流水线集成

作为流水线第一步（设计阶段）时：
1. Claude 分析需求，构建 UI 设计 prompt
2. 调用 cursor-run.sh（或 Windows 上的 cursor-run.ps1）生成 UI 代码
3. Claude 读取生成的文件，提取关键设计信息
4. 将 UI 设计上下文传递给下一步（cursor-code-agent 实现业务逻辑）

## 与 gemini-agent 的关系

cursor-ui-agent 是 gemini-agent 的替代方案：
- **gemini-agent**: 直接调用 Gemini CLI（需要安装 Gemini CLI）
- **cursor-ui-agent**: 通过 Cursor Agent CLI 调用 Gemini 3.1 Pro（只需安装 Cursor）

**优先级**：`gemini-agent`（如 Gemini CLI 已安装）> `cursor-ui-agent`（仅需 Cursor CLI）

## 任务路由

当用户请求包含以下关键词时，且 Gemini CLI 不可用时，路由到 cursor-ui-agent：
- 设计、UI、组件、页面、布局、样式、美化、前端、界面、视觉
