# PM_Manager — AutoCAD 实用工具集

一组可直接通过 APPLOAD 加载的 AutoCAD LISP 工具，每个文件独立可运行，运行时自动加载 `lib-pm/` 库模块。

## 命令文件

| 文件 | 命令 | 功能 |
|------|------|------|
| `SumLength 长度求和.LSP` | `SumLength` | 选择多条曲线对象，汇总总长度 |
| `SumArea 面积求和.LSP` | `SumArea` | 按类型汇总对象面积并显示总计 |
| `CountBlock 统计块数量.LSP` | `CountBlock` | 统计全图中同名块的数量并标注 |
| `AreaLabel 面积标注.lsp` | `AreaLabel` | 在封闭区域内点选后自动标注面积 |
| `FlattenZ Z轴归零.LSP` | `FlattenZ` | 实体 Z 坐标归零、厚度归零、拉伸方向归正 |
| `AddVertex 多段线添加顶点.LSP` | `AddVertex` | 向轻量多段线指定位置插入新顶点 |
| `AutoCorrect 顶点自动规整.LSP` | `AutoCorrect` | 将图元坐标/顶点归算到整数倍容差 |
| `ChangeBlockBase 修改块基点.LSP` | `ChangeBasePoint` / `ChangeBasePointRetainPosition` | 修改块参照的基点 |

## 库模块 (`lib-pm/`)

| 文件 | 内容 |
|------|------|
| `PM_Core.lsp` | 核心基础：错误处理、数学计算、矩阵运算、撤销标记、选择集封装 |
| `PM_Block.lsp` | 块参照操作：块名查询、数量统计 |
| `PM_Entity.lsp` | 图元操作：面积/长度计算、顶点提取、Z轴归零、DXF组码读写 |
| `PM_Layer.lsp` | 图层操作：图层解锁/恢复、解冻 |
| `PM_Text.lsp` | 文字操作：创建单行文字、文字高度获取 |
| `PM_DCL.lsp` | 动态 DCL 对话框生成 |

## 使用方法

在 AutoCAD 中执行 `APPLOAD`，选择任意命令文件即可加载。加载后输入对应的命令名称运行。

库模块在首次执行命令时自动按需加载，无需手动初始化。
