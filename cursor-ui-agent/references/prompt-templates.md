# Cursor UI Agent Prompt 模板库

使用 Cursor Agent (Gemini 3.1 Pro) 进行 UI 设计时的提示词模板。

---

## 通用 UI 设计模板

```
You are a world-class UI designer and frontend developer using Gemini 3.1 Pro.
Create a beautiful, modern, accessible, and high-performance UI component.

## Task
{用户的 UI 描述}

## Tech Stack
- Framework: {React/Vue/HTML} + {Tailwind CSS / plain CSS}
- Output path: {文件路径}

## Code Standards
1. Semantic HTML: use proper elements (button, nav, main, article, etc.)
2. Accessibility: ARIA attributes, keyboard navigation, label associations
3. Button defaults: all buttons have type="button" unless explicitly submit
4. Responsive: mobile-first with breakpoints
5. State handling: include loading, error, and empty states
6. TypeScript: define Props interfaces

## Design Style
- Modern and clean, appropriate spacing and border-radius
- Clear visual hierarchy
- Micro-interactions (hover, focus, active transitions)

## Output Requirements
- Generate production-ready code directly into the specified file
- No explanations, output code only
```

---

## 表单组件模板

```
Create a {form type} form component.

Requirements:
- All inputs have associated labels (htmlFor/id)
- Error messages use aria-describedby
- Validation states use aria-invalid
- Submit button has type="submit", all others type="button"
- Include loading state during submission
- Responsive layout

Output to: {文件路径}
```

---

## 导航组件模板

```
Create a {navigation type} navigation component.

Requirements:
- Use <nav> semantic element
- Active page uses aria-current="page"
- Mobile hamburger menu uses aria-expanded
- Keyboard navigable (Tab/Enter/Escape)
- Responsive breakpoint switching

Output to: {文件路径}
```

---

## 模态框/对话框模板

```
Create a {modal type} modal dialog component.

Requirements:
- aria-modal="true" and role="dialog"
- Focus trap (focus locked inside modal when open)
- ESC key closes the modal
- Clicking the overlay closes the modal
- Open/close transition animations

Output to: {文件路径}
```

---

## Dashboard 页面模板

```
Create a {dashboard type} admin dashboard page.

Requirements:
- Responsive grid layout (single column on mobile, multi-column on desktop)
- Data card components (stats, trend indicators)
- Sidebar navigation
- Top search bar and user menu
- Skeleton loading states

Output to: {文件路径}
```

---

## 流水线模式 - 设计阶段模板

```
You are a world-class UI/UX designer and frontend developer using Gemini 3.1 Pro.

## Task
Design and implement the following UI based on these requirements:
{需求描述}

## Design Process
1. Plan the page structure and component hierarchy
2. Determine the color scheme and visual style
3. Implement the complete UI code

## Output Files
Write the code to the following paths:
{文件路径列表}

## Conventions
- Components use clear Props interfaces
- Mark data binding points with TODO comments for backend integration
- Separate styles from logic to facilitate business logic implementation later
```

---

## 组件库模板

```
Create a reusable {component type} component for a design system.

Requirements:
- Configurable via props (size, variant, color, disabled, etc.)
- Export TypeScript types for all props
- Include usage examples in a comment at the top of the file
- Storybook-compatible prop documentation

Output to: {文件路径}
```
