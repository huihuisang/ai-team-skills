# Cursor Code Agent Prompt 模板库

使用 Cursor Agent (GPT-5.3 Codex) 进行代码实现时的提示词模板。

---

## 通用代码实现模板

```
You are a senior software engineer. Complete the following coding task.

## Task
{任务描述}

## Project Context
- Language/Framework: {技术栈}
- Project structure: {关键目录和文件}
- Related files: {需要参考或修改的文件路径}

## Requirements
1. Follow the existing coding style and conventions
2. Add necessary error handling
3. Ensure type safety where applicable
4. Code must be production-ready and runnable

## Output
Write code to the following files:
{文件路径列表}
```

---

## Bug 修复模板

```
Fix the following bug:

## Problem Description
{bug 描述}

## Steps to Reproduce
{复现步骤}

## Related Files
{文件路径列表}

## Expected Behavior
{修复后的期望行为}

Identify the root cause and fix it without introducing new issues.
```

---

## API 实现模板

```
Implement the following API endpoint:

## Endpoint Definition
- Method: {GET/POST/PUT/DELETE}
- Path: {API 路径}
- Request body: {请求格式}
- Response body: {响应格式}

## Requirements
- Input validation
- Error handling (return appropriate HTTP status codes)
- Database operations (if applicable)
- Auth/authorization checks (if applicable)

## Related Files
{路由文件、控制器文件、模型文件路径}
```

---

## 重构模板

```
Refactor the following code:

## Goal
{重构目标: improve readability / performance / maintainability}

## Current Code Location
{文件路径}

## Refactoring Requirements
- Keep the external interface unchanged
- Do not change existing behavior
- {具体重构要求}

## Constraints
- Do not introduce new dependencies
- Maintain backward compatibility
```

---

## 测试编写模板

```
Write tests for the following code:

## Code Under Test
{文件路径和函数/类名}

## Test Framework
{Jest/Vitest/pytest/Go test, etc.}

## Test Requirements
- Cover happy paths and edge cases
- Cover error handling paths
- Mock external dependencies
- Write test file to: {测试文件路径}
```

---

## 代码 Review 模板（plan 模式使用）

```
Review the following code and provide a detailed analysis:

## Files to Review
{文件路径列表}

## Review Focus
- Code quality and readability
- Potential bugs or edge cases
- Security vulnerabilities
- Performance concerns
- Adherence to best practices

## Output Format
Provide a structured report with:
1. Summary
2. Critical issues (must fix)
3. Suggestions (nice to have)
4. Positive observations
```

---

## 流水线模式 - 实现阶段模板

```
You are a senior full-stack engineer. Based on the existing UI design code,
implement the complete business logic.

## UI Design Context
The following files contain the generated UI code (designed by Gemini/Cursor UI Agent):
{UI 文件路径列表}

Key design decisions:
{从 UI 代码中提取的关键信息}

## Implementation Task
{需要实现的业务逻辑描述}

## Requirements
1. Keep the UI component structure unchanged
2. Implement data fetching, state management, and event handling
3. Connect to API endpoints
4. Add error handling and loading states
5. Ensure type safety

## Output
Modify or create the following files:
{文件路径列表}
```
