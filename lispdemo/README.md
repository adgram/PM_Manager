﻿# PM_Manager — AutoCAD 实用工具集

一组可直接通过 APPLOAD 加载的 AutoCAD LISP 工具。多数工具运行时自动加载 `lib-pm/` 库模块；`ChangeBlockBase` 为独立脚本，无需库支持。

## 命令文件

| 文件 | 命令 | 功能 |
|------|------|------|
| `SumLength 长度求和.LSP` | `SumLength` | 选择曲线和文字，汇总总长度（支持单位换算） |
| `SumArea 面积求和.LSP` | `SumArea` | 按类型汇总对象面积（支持单位换算、混合选文字） |
| `CountBlock 统计块数量.LSP` | `CountBlock` | 选择块参照，统计全图中同名块的数量并标注 |
| `AreaLabel 面积标注.lsp` | `AreaLabel` | 在封闭区域内点选后自动标注面积 |
| `FlattenZ Z轴归零.LSP` | `FlattenZ` | 实体 Z 坐标归零、厚度归零、拉伸方向归正 |
| `AddVertex 多段线添加顶点.LSP` | `AddVertex` | 向轻量多段线指定位置插入新顶点 |
| `AutoCorrect 顶点自动规整.LSP` | `AutoCorrect` | 将图元坐标/顶点归算到整数倍容差 |
| `ChangeBlockBase 修改块基点.LSP` | `ChangeBasePoint` / `ChangeBasePointRetainPosition` | 修改块参照的基点（独立脚本，无需 lib-pm） |
| `LayerTool 图层管理.LSP` | `PMLayer` / `PMLayerCreate` / `PMLayerQuick` / `PMLayerOnAll` / `PMLayerThawAll` / `PMLayerOff` / `PMLayerOffOthers` | 创建/切换图层、图层全开/解冻、关闭图层/关闭其他 |

## 前置要求

除 ChangeBlockBase 外的工具需要配置搜索路径，详见 [`lib-pm/README.md`](lib-pm/README.md)。

## 使用方法

在 AutoCAD 中执行 `APPLOAD`，选择任意命令文件即可加载。加载后输入对应的命令名称运行。
库模块在首次执行命令时自动按需加载。

## 库模块

详见 [`lib-pm/README.md`](lib-pm/README.md)。

---

---

# PM_Manager — AutoCAD Utility Toolkit

A collection of AutoCAD LISP tools loadable via `APPLOAD`. Most tools auto-load the `lib-pm/` library modules at runtime; `ChangeBlockBase` is a standalone script with no library dependency.

## Command Files

| File | Commands | Description |
|------|----------|-------------|
| `SumLength 长度求和.LSP` | `SumLength` | Sum lengths of curves and text (with unit conversion) |
| `SumArea 面积求和.LSP` | `SumArea` | Summarize object area by type (with unit conversion, mixed text selection) |
| `CountBlock 统计块数量.LSP` | `CountBlock` | Count and annotate identical block references |
| `AreaLabel 面积标注.lsp` | `AreaLabel` | Pick inside a closed boundary to auto-label its area |
| `FlattenZ Z轴归零.LSP` | `FlattenZ` | Flatten Z coordinate, thickness, and extrusion direction |
| `AddVertex 多段线添加顶点.LSP` | `AddVertex` | Insert a new vertex into a lightweight polyline |
| `AutoCorrect 顶点自动规整.LSP` | `AutoCorrect` | Snap entity coordinates/vertices to integer tolerance |
| `ChangeBlockBase 修改块基点.LSP` | `ChangeBasePoint` / `ChangeBasePointRetainPosition` | Change block reference base point (standalone, no lib-pm) |
| `LayerTool 图层管理.LSP` | `PMLayer` / `PMLayerCreate` / `PMLayerQuick` / `PMLayerOnAll` / `PMLayerThawAll` / `PMLayerOff` / `PMLayerOffOthers` | Create/switch layers; turn on/thaw all; turn off selected/others |

## Prerequisites

Tools other than `ChangeBlockBase` require the `lispdemo` directory to be in AutoCAD's support file search path. See [`lib-pm/README.md`](lib-pm/README.md).

## Usage

Run `APPLOAD` in AutoCAD, select a command file to load, then type the corresponding command name.
Library modules are auto-loaded on first command execution.

## Library Modules

See [`lib-pm/README.md`](lib-pm/README.md).
