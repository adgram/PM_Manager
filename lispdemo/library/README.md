# PM_Manager 工具库分类说明

## 分类标准

按 **功能领域** 拆分文件，而非按函数数量。每个模块文件只负责**一个正交领域**，彼此无循环依赖。

## 文件结构

```
library/
├── init.lsp       ← 入口，加载所有模块
├── PM_Core.lsp    ← 核心基础
├── PM_Text.lsp    ← 文字操作
└── PM_Block.lsp   ← 块操作
```

### 各文件职责

| 文件 | 职责范围 | 示例函数 | 可放入的内容 |
|------|---------|---------|-------------|
| **PM_Core.lsp** | 通用基础设施，**不依赖任何其他模块** | `PM:ErrorHandler` | 错误处理、系统变量工具、数学工具、通用列表操作 |
| **PM_Text.lsp** | 文字/标注相关 | `PM:GetTextSize`, `PM:MakeText` | 文字创建、文字样式、文字编辑、标注操作 |
| **PM_Block.lsp** | 块参照相关 | `PM:CountBlockByName`, `PM:GetBlockName` | 块统计、块属性读写、块替换、嵌套块遍历 |
| *未来扩展* | 分层/实体/选择集等 | — | 按相同原则新增 `PM_Layer.lsp`, `PM_Select.lsp` 等 |

## 判断规则

- **如果两个函数分别属于不同逻辑领域** → 分开放到不同文件
- **如果两个函数属于同一个领域** → 放在同一个文件
- **如果函数 A 依赖函数 B 才能工作** → 优先放在同一文件，或确保 B 在更基础的模块中

  例：`PM:MakeText` 属于文字领域 → `PM_Text.lsp`；`PM:CountBlockByName` 属于块领域 → `PM_Block.lsp`

- **如果某个文件超过 200~300 行** → 考虑按子领域进一步拆分

## 如何使用

在命令文件中只需加载入口：

```lisp
(load "library/init")      ; 加载所有模块
```

之后即可调用任意库函数：

```lisp
(setq size (PM:GetTextSize))
(PM:MakeText pt size "Hello")
```

## 扩展指南

新增功能时，先判断所属领域：
- 图层操作 → 新建 `PM_Layer.lsp`
- 选择集操作 → 新建 `PM_Select.lsp`
- 实体编辑 → 新建 `PM_Entity.lsp`

然后在 `init.lsp` 中添加一行 `(load "PM_xxx")` 即可。
