# ACAD-PM — AutoCAD 插件管理器 / Plugin Manager

[中文](#中文) | [English](#english)

---

## 中文

AutoCAD 插件管理器，自动递归扫描目录下的 `.lsp` / `.fas` / `.vlx`，提供 GUI 进行加载、卸载和自动加载管理。

### 命令

| 命令 | 说明 |
|------|------|
| `PM` | 打开插件管理器对话框 |
| `PM_AUTOLOAD` | 手动执行自动加载 |

### 安装

1. 将 `PM_Manager.LSP` 放入 AutoCAD 支持路径
2. `APPLOAD` 加载该文件
3. 添加到启动组可在 CAD 启动时自动加载

### 界面说明

**插件列表** — 显示文件夹及其插件文件。每行标注加载状态和自动加载状态。空格多选，选中文件夹行作用于其下所有文件。

**加载选中** / **卸载选中** — 加载/卸载选中的插件；选中文件夹则作用于所有文件。

**全部自动** — 将所有插件设为自动加载。**切换自动/手动** — 切换选中项的自动状态。

**+ 添加路径** / **- 删除路径** — 管理监视目录。

### 配置文件

```
%APPDATA%\Autodesk\AutoCAD 20xx\Rxx.x\chs\ACAD-PM\acad-pm.cfg
```

```
[Paths]
C:\Users\用户名\lisp

[Auto]
插件1.lsp
```

### 工作原理

1. 启动时读取配置，获取监视目录
2. 递归扫描所有目录及子目录，发现 `.lsp` / `.fas` / `.vlx`
3. 按 `[Auto]` 配置自动加载
4. `PM` 打开 GUI 管理
5. 操作实时落盘

---

## English

A lightweight plugin manager for AutoCAD that recursively scans directories for `.lsp` / `.fas` / `.vlx` files and provides a GUI for loading, unloading, and managing auto-load plugins.

### Commands

| Command | Description |
|---------|-------------|
| `PM` | Open the plugin manager dialog |
| `PM_AUTOLOAD` | Manually trigger auto-load |

### Installation

1. Place `PM_Manager.LSP` in an AutoCAD support path
2. Run `APPLOAD` in AutoCAD and select the file
3. Add it to the Startup Suite for automatic loading on CAD launch

### UI Overview

**Plugin List** — Displays folders and plugin files. Each entry shows load status and auto-load status. Multi-select with Space. Selecting a folder applies the action to all files under it.

**Load Selected** / **Unload Selected** — Load/unload selected plugins; selecting a folder applies to all files.

**All Auto** — Set all plugins to auto-load. **Toggle Auto/Manual** — Toggle auto-load status for selected items.

**+ Add Path** / **- Delete Path** — Manage monitored directories.

### Configuration File

```
%APPDATA%\Autodesk\AutoCAD 20xx\Rxx.x\chs\ACAD-PM\acad-pm.cfg
```

```
[Paths]
C:\Users\username\lisp

[Auto]
plugin1.lsp
```

### How It Works

1. Startup reads config for monitored directories
2. Recursively scans all directories and subdirectories for `.lsp` / `.fas` / `.vlx`
3. Auto-loads plugins per `[Auto]` config
4. `PM` opens the GUI for management
5. All changes saved to config immediately
