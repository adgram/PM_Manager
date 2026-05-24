# ACAD-PM — AutoCAD Plugin Manager

> This documentation is bilingual. See [README.md](./README.md) for the full document with language toggle.

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

For full documentation (including UI overview and Chinese version), please refer to [README.md](./README.md).
