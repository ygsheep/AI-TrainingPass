# AI 训考通 - UI 设计规范

## 设计系统概览

| 元素 | 选择 | 理由 |
|------|------|------|
| **风格** | Minimalism & Swiss Style | 专业、简洁、适合学习平台 |
| **布局** | 网格系统、卡片式 | 内容组织清晰，易于扫描 |
| **字体** | Fira Code + Fira Sans | 数据展示友好，技术感 |
| **圆角** | 8px / 12px / 16px | 现代、友好不过于圆润 |
| **阴影** | 柔和、多层次 | 营造层次感 |

---

## 一、颜色系统

### 1.1 四种主题配色

#### 默认主题 - 现代科技
```css
:root {
  /* 主色调 - 靛蓝渐变 */
  --primary: #6366f1;
  --primary-light: #818cf8;
  --primary-dark: #4f46e5;

  /* 强调色 - 粉红 */
  --secondary: #ec4899;
  --secondary-light: #f472b6;
  --secondary-dark: #db2777;

  /* 辅助色 - 青色 */
  --accent: #14b8a6;
  --accent-light: #2dd4bf;
  --accent-dark: #0d9488;

  /* 背景色 */
  --background: #f8fafc;
  --surface: #ffffff;

  /* 文字色 */
  --text: #1e293b;
  --text-secondary: #64748b;
  --text-muted: #94a3b8;

  /* 功能色 */
  --success: #22c55e;
  --warning: #f59e0b;
  --error: #ef4444;
  --info: #3b82f6;
}
```

#### 蓝色专业 - 专注学习
```css
[data-theme="blue"] {
  --primary: #2563eb;
  --primary-light: #3b82f6;
  --primary-dark: #1d4ed8;

  --secondary: #6366f1;
  --secondary-light: #818cf8;
  --secondary-dark: #4f46e5;

  --accent: #06b6d4;
  --accent-light: #22d3ee;
  --accent-dark: #0891b2;

  --background: #f1f5f9;
  --surface: #ffffff;

  --text: #0f172a;
  --text-secondary: #475569;
  --text-muted: #94a3b8;
}
```

#### 绿色清新 - 护眼舒适
```css
[data-theme="green"] {
  --primary: #059669;
  --primary-light: #10b981;
  --primary-dark: #047857;

  --secondary: #14b8a6;
  --secondary-light: #2dd4bf;
  --secondary-dark: #0d9488;

  --accent: #84cc16;
  --accent-light: #a3e635;
  --accent-dark: #65a30d;

  --background: #f0fdf4;
  --surface: #ffffff;

  --text: #14532d;
  --text-secondary: #166534;
  --text-muted: #6ee7b7;
}
```

#### 深色模式 - 深色护眼
```css
[data-theme="dark"] {
  --primary: #818cf8;
  --primary-light: #a5b4fc;
  --primary-dark: #6366f1;

  --secondary: #f472b6;
  --secondary-light: #f9a8d4;
  --secondary-dark: #ec4899;

  --accent: #2dd4bf;
  --accent-light: #5eead4;
  --accent-dark: #14b8a6;

  --background: #0f172a;
  --surface: #1e293b;

  --text: #f1f5f9;
  --text-secondary: #cbd5e1;
  --text-muted: #64748b;
}
```

### 1.2 渐变配色

```css
/* 主渐变 - 用于按钮、卡片强调 */
--gradient-primary: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
--gradient-subtle: linear-gradient(135deg, var(--primary-light) 0%, var(--accent) 100%);

/* 背景渐变 */
--gradient-bg: linear-gradient(180deg, var(--background) 0%, var(--surface) 100%);
--gradient-card: linear-gradient(145deg, var(--surface) 0%, rgba(255,255,255,0.5) 100%);
```

---

## 二、字体系统

### 2.1 字体族

```css
/* Google Fonts 导入 */
@import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500;600;700&family=Fira+Sans:wght@300;400;500;600;700&display=swap');

/* 字体变量 */
--font-heading: 'Fira Sans', system-ui, sans-serif;
--font-body: 'Fira Sans', system-ui, sans-serif;
--font-mono: 'Fira Code', 'Consolas', monospace;
```

### 2.2 字体大小与行高

```css
/* 标题 */
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */
--text-4xl: 2.25rem;   /* 36px */

/* 行高 */
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

### 2.3 字重

```css
--font-light: 300;
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

### 2.4 应用规则

| 用途 | 字体大小 | 字重 | 行高 |
|------|----------|------|------|
| 页面标题 | 2rem (32px) | 700 | 1.25 |
| 卡片标题 | 1.25rem (20px) | 600 | 1.4 |
| 正文 | 1rem (16px) | 400 | 1.6 |
| 辅助文字 | 0.875rem (14px) | 400 | 1.5 |
| 代码/数据 | 0.875rem (14px) | 500 | 1.4 |

---

## 三、间距系统

### 3.1 间距比例（基于 4px 网格）

```css
--spacing-0: 0;
--spacing-1: 0.25rem;  /* 4px */
--spacing-2: 0.5rem;   /* 8px */
--spacing-3: 0.75rem;  /* 12px */
--spacing-4: 1rem;     /* 16px */
--spacing-5: 1.25rem;  /* 20px */
--spacing-6: 1.5rem;   /* 24px */
--spacing-8: 2rem;     /* 32px */
--spacing-10: 2.5rem;  /* 40px */
--spacing-12: 3rem;    /* 48px */
--spacing-16: 4rem;    /* 64px */
```

### 3.2 组件内间距

| 组件 | 内边距 | 外边距 |
|------|--------|--------|
| 按钮 | 0.75rem 1.5rem | 根据布局 |
| 卡片 | 1.5rem | 1rem |
| 输入框 | 0.75rem 1rem | 0.5rem |
| 标签 | 0.25rem 0.75rem | 0.25rem |

---

## 四、圆角与阴影

### 4.1 圆角

```css
--radius-sm: 8px;
--radius-md: 12px;
--radius-lg: 16px;
--radius-xl: 24px;
--radius-full: 9999px;
```

### 4.2 阴影

```css
--shadow-xs: 0 1px 2px rgba(0,0,0,0.05);
--shadow-sm: 0 1px 3px rgba(0,0,0,0.1);
--shadow-md: 0 4px 6px -1px rgba(0,0,0,0.1);
--shadow-lg: 0 10px 15px -3px rgba(0,0,0,0.1);
--shadow-xl: 0 20px 25px -5px rgba(0,0,0,0.1);

/* 彩色阴影（用于强调元素） */
--shadow-primary: 0 4px 14px rgba(99, 102, 241, 0.3);
--shadow-secondary: 0 4px 14px rgba(236, 72, 153, 0.3);
--shadow-accent: 0 4px 14px rgba(20, 184, 166, 0.3);
```

---

## 五、组件规范

### 5.1 按钮

#### 主要按钮（Primary）
```tsx
// 代码示例
<Button className="bg-primary hover:bg-primary-dark text-white font-medium px-6 py-3 rounded-lg shadow-primary transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5">
  开始练习
</Button>
```

| 状态 | 背景色 | 文字色 | 阴影 |
|------|--------|--------|------|
| 默认 | `var(--primary)` | 白色 | `shadow-primary` |
| 悬停 | `var(--primary-dark)` | 白色 | `shadow-lg` |
| 点击 | `var(--primary-dark)` | 白色 | `shadow-sm` |
| 禁用 | `var(--text-muted)` | `var(--text-muted)` | 无 |

#### 次要按钮（Secondary）
```tsx
<Button variant="outline" className="border-2 border-primary text-primary hover:bg-primary/10 font-medium px-6 py-3 rounded-lg transition-all duration-200">
  查看详情
</Button>
```

#### 文字按钮（Ghost）
```tsx
<Button variant="ghost" className="text-text-secondary hover:text-primary hover:bg-primary/5 px-4 py-2 rounded-lg transition-all duration-150">
  取消
</Button>
```

### 5.2 卡片

#### 基础卡片
```tsx
<Card className="bg-surface rounded-xl shadow-md hover:shadow-lg transition-shadow duration-300 border border-gray-100 dark:border-gray-800">
  <CardHeader>
    <CardTitle className="text-xl font-semibold text-text">今日学习</CardTitle>
  </CardHeader>
  <CardContent>
    {/* 内容 */}
  </CardContent>
</Card>
```

#### 可点击卡片
```tsx
<Card className="bg-surface rounded-xl shadow-md hover:shadow-xl hover:-translate-y-1 transition-all duration-300 cursor-pointer border border-transparent hover:border-primary/30">
  {/* 内容 */}
</Card>
```

### 5.3 进度条

```tsx
// 基础进度条
<div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
  <div
    className="h-full bg-gradient-to-r from-primary to-secondary rounded-full transition-all duration-500 ease-out"
    style={{ width: '60%' }}
  />
</div>

// 带标签的进度条
<div className="space-y-2">
  <div className="flex justify-between text-sm">
    <span className="font-medium">学习进度</span>
    <span className="text-primary">60%</span>
  </div>
  <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
    <div className="h-full bg-gradient-to-r from-primary to-secondary" style={{ width: '60%' }} />
  </div>
</div>
```

### 5.4 标签

```tsx
// 基础标签
<Badge className="px-3 py-1 rounded-full text-xs font-medium bg-primary/10 text-primary border border-primary/20">
  机器学习
</Badge>

// 状态标签
<Badge variant="success">已完成</Badge>
<Badge variant="warning">进行中</Badge>
<Badge variant="error">错误</Badge>
```

---

## 六、页面布局

### 6.1 主布局结构

```
┌─────────────────────────────────────────────────────────┐
│  Header (固定)                                           │
│  Logo | 导航 | 主题切换 | 用户                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  主内容区                                                │
│  ┌────────────┬────────────────────────────────────┐    │
│  │            │                                     │    │
│  │  Sidebar   │         Content                    │    │
│  │ (可选)     │                                     │    │
│  │            │                                     │    │
│  └────────────┴────────────────────────────────────┘    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 6.2 响应式断点

```css
/* 移动端优先 */
sm: 640px   /* 小屏幕 */
md: 768px   /* 平板 - 侧边栏显示 */
lg: 1024px  /* 桌面 */
xl: 1280px  /* 大屏 */
2xl: 1536px /* 超大屏 */
```

### 6.3 容器宽度

```css
--container-sm: 640px;
--container-md: 768px;
--container-lg: 1024px;
--container-xl: 1280px;
```

---

## 七、动效规范

### 7.1 过渡时间

```css
--transition-fast: 150ms;   /* 微交互 */
--transition-base: 200ms;   /* 标准过渡 */
--transition-slow: 300ms;   /* 大面积元素 */
--transition-slower: 500ms; /* 页面切换 */
```

### 7.2 缓动函数

```css
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
```

### 7.3 常用动效

| 交互 | 动效 | 持续时间 |
|------|------|----------|
| 按钮悬停 | 阴影加深 + 轻微上浮 | 150ms |
| 卡片悬停 | 阴影加深 + Y轴位移 -2px | 200ms |
| 页面切换 | 淡入淡出 | 300ms |
| 加载状态 | 骨架屏闪烁 | 1.5s循环 |
| 模态框打开 | 缩放 + 淡入 | 200ms |

### 7.4 尊重用户偏好

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 八、图标规范

### 8.1 图标库

- **主要**: Heroicons / Lucide React
- **尺寸**: 20px (sm), 24px (base), 32px (lg)

### 8.2 使用规则

```tsx
// 图标按钮
<button className="p-2 rounded-lg hover:bg-gray-100 transition-colors">
  <Icon className="w-5 h-5" />
</button>

// 带文字的图标
<div className="flex items-center gap-2">
  <Icon className="w-4 h-4 text-primary" />
  <span>文字</span>
</div>
```

---

## 九、可访问性

### 9.1 颜色对比度

- 正文文字: 最小 4.5:1
- 大文字 (18px+): 最小 3:1
- 图标/图形: 最小 3:1

### 9.2 焦点状态

```css
*:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}
```

### 9.3 ARIA 标签

```tsx
// 图标按钮需要 aria-label
<button aria-label="关闭">
  <XIcon className="w-5 h-5" />
</button>

// 加载状态
<div role="status" aria-live="polite">
  <Spinner aria-hidden="true" />
  <span className="sr-only">加载中...</span>
</div>
```

---

## 十、shadcn/ui 组件使用

### 10.1 复合组件模式

```tsx
// ✅ 推荐
<Card>
  <CardHeader>
    <CardTitle>标题</CardTitle>
    <CardDescription>描述</CardDescription>
  </CardHeader>
  <CardContent>内容</CardContent>
</Card>

// ❌ 避免
<Card title="标题" description="描述" content="内容" />
```

### 10.2 Chart 组件

```tsx
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"

<ChartContainer config={chartConfig}>
  <ResponsiveContainer width="100%" height={300}>
    <BarChart data={data}>
      <ChartTooltip content={<ChartTooltipContent />} />
      <Bar dataKey="value" fill="var(--primary)" />
    </BarChart>
  </ResponsiveContainer>
</ChartContainer>
```

### 10.3 Toaster 位置

```tsx
// app/layout.tsx 或根组件
export default function RootLayout() {
  return (
    <html>
      <body>
        <App />
        <Toaster /> {/* 在根级别添加 */}
      </body>
    </html>
  );
}
```

---

## 十一、预交付检查清单

### 视觉质量
- [ ] 不使用 emoji 作为图标（使用 SVG）
- [ ] 所有图标来自一致图标集（Heroicons/Lucide）
- [ ] 悬停状态不会导致布局偏移
- [ ] 直接使用主题颜色（bg-primary）而非 var() 包装

### 交互
- [ ] 所有可点击元素有 `cursor-pointer`
- [ ] 悬停状态提供清晰的视觉反馈
- [ ] 过渡平滑（150-300ms）
- [ ] 键盘导航焦点状态可见

### 明暗模式
- [ ] 明模式文字对比度 ≥ 4.5:1
- [ ] 玻璃/透明元素在明模式下可见
- [ ] 边框在两种模式下都可见
- [ ] 测试两种模式后再交付

### 布局
- [ ] 浮动元素有适当的边缘间距
- [ ] 没有内容隐藏在固定导航栏后面
- [ ] 响应式在 375px, 768px, 1024px, 1440px 测试
- [ ] 移动端没有水平滚动

### 可访问性
- [ ] 所有图片有 alt 文本
- [ ] 表单输入有标签
- [ ] 颜色不是唯一的指示器
- [ ] 尊重 `prefers-reduced-motion`
