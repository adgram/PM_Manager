# PM_Manager 工具库

## 前置要求

命令文件和库文件通过相对路径引用（如 `(load "lib-pm/PM_Core")`），因此 **`lispdemo` 目录必须位于 AutoCAD 的支持文件搜索路径中**，否则加载会失败。

### 添加搜索路径的方法

**通过菜单添加（持久化，推荐）**
1. 输入 `OPTIONS` 命令
2. 切换到 **文件** 选项卡
3. 展开 **支持文件搜索路径**
4. 点击 **添加** → **浏览**，选择 `.\PM_Manager\lispdemo`
5. 点击 **确定** 保存

## 文件结构

```
lib-pm/
├── PM_Core.lsp      ← 核心基础（单位换算、通用工具）
├── PM_Entity.lsp    ← 实体操作（面积、长度、DXF 读写）
├── PM_Text.lsp      ← 文字操作（创建、比例尺）
├── PM_Layer.lsp     ← 图层操作（创建/切换/开关/冻结/锁定）
├── PM_Block.lsp     ← 块操作
├── PM_DCL.lsp       ← 动态 DCL 对话框生成
└── PM_TArch.lsp     ← 天正工具集成
```

### 各文件职责

| 文件 | 职责范围 | 示例函数 |
|------|---------|---------|
| **PM_Core.lsp** | 通用基础设施，不依赖其他模块 | `PM:ErrorHandler`, `PM:ValueFromText`, `PM:ConvertLength` |
| **PM_Entity.lsp** | 实体/图元操作，依赖 PM_Core | `PM:GetCurveLength`, `PM:GetObjectArea`, `PM:GetDXF` |
| **PM_Text.lsp** | 文字/标注相关，依赖 PM_Core | `PM:MakeText`, `PM:MakeScaledText`, `C:PMScale` |
| **PM_Layer.lsp** | 图层创建/切换/开关/冻结/锁定 | `PM:CreateLayer`, `PM:SetLayerCurrent`, `PM:TurnOnAllLayers`, `PM:ThawAllLayers`, `PM:TurnOffLayers`, `PM:TurnOffOtherLayers`, `PM:CreateLayerWithProps`（支持真彩色和线型） |
| **PM_Block.lsp** | 块参照相关 | `PM:CountBlockByName`, `PM:GetBlockName` |
| **PM_DCL.lsp** | 动态 DCL 对话框生成 | `PM:DCLDialog` |
| **PM_TArch.lsp** | 天正环境检测、读取出图比例 | `PM:TArchLoaded`, `PM:GetTArchScale` |

## 单位换算系统

四个模式通过 `C:PMUnit` 命令切换：

| 模式 | 图纸单位 | 标注单位 | 示例 |
|------|---------|---------|------|
| `mm-mm` | 毫米 | 毫米 | 10000 mm → 10000 mm |
| `m-m` | 米 | 米 | 10000 m → 10000 m |
| `mm-m`（默认） | 毫米 | 米 | 10000 mm → 10 m |
| `m-mm` | 米 | 毫米 | 10 m → 10000 mm |

### 文字解析

`PM:ValueFromText` 从文字内容提取数值并自动识别单位后缀：

- `长度:10m` → 识别 `m`，按图纸单位换算后参与累加
- `面积:10000mm²` → 识别 `mm²`，按图纸单位换算后参与累加
- 无后缀文字 → 假设已在图纸单位

## 比例尺系统（PM_Text.lsp）

- `*PM:Scale*` — 全局比例尺，默认 100（1:100）
- `C:PMScale` — 交互设置比例尺
- `PM:MakeScaledText` — 按比例尺创建文字（图纸高度 3.5 × 比例尺）

## 命令文件集成示例

```lisp
(defun c:MyCmd ()
  (or *PM-Core-Loaded* (load "lib-pm/PM_Core"))
  (or *PM-Entity-Loaded* (load "lib-pm/PM_Entity"))
  ;; ... 业务逻辑
)
```

命令文件中先调用 `(vl-load-com)`，再用相对路径加载库模块，AutoCAD 会通过支持文件搜索路径找到它们。
