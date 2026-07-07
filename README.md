This plugin was generated and implemented by Codex for Hh20070324.

# windows-clipboard.yazi

Use the Windows native file clipboard from Yazi.

`windows-clipboard.yazi` lets Yazi copy, cut, paste, archive, and extract files through Windows-native tooling.

## Features

- Copy selected files, or the hovered file if nothing is selected.
- Cut selected files, or the hovered file if nothing is selected.
- Paste files from the Windows file clipboard into the current Yazi directory.
- Archive selected files to `.zip`.
- Extract selected archives into the current Yazi directory.
- Preserve Windows copy/cut semantics with `Preferred DropEffect`.
- Rename pasted files automatically when the target name already exists:
  - `example - Copy.txt`
  - `example - Copy (2).txt`
  - `Folder - Copy`
- Capture PowerShell output inside the plugin and show failures through Yazi notifications.

## Requirements

- Windows
- Yazi 26.5.6 or newer
- PowerShell 7 available as `pwsh`
- 7-Zip for archive and extract actions. This plugin calls the 7-Zip CLI; Yazi itself does not provide these archive operations.

7-Zip is detected in this order:

1. `YAZI_WINDOWS_CLIPBOARD_7Z`
2. `7z.exe` on `PATH`
3. Common install paths such as `C:\Program Files\7-Zip\7z.exe`

## Installation

### Recommended

```powershell
ya pkg add Hh20070324/windows-clipboard.yazi
```

Then add the key bindings to your `keymap.toml`:

```toml
[mgr]
prepend_keymap = [
    { on = "c", run = "plugin windows-clipboard -- copy",  desc = "Copy files to Windows clipboard" },
    { on = "x", run = "plugin windows-clipboard -- cut",   desc = "Cut files to Windows clipboard" },
    { on = "v", run = "plugin windows-clipboard -- paste", desc = "Paste files from Windows clipboard" },
    { on = "<A-a>", run = "plugin windows-clipboard -- archive", desc = "Archive selected files" },
    { on = "<A-e>", run = "plugin windows-clipboard -- extract", desc = "Extract selected archives" },
]
```

### Manual local installation

Copy this directory to:

```text
%APPDATA%\yazi\config\plugins\windows-clipboard.yazi
```

Then add the same key bindings shown above to `keymap.toml`.

## Usage

| Key | Action |
|-----|--------|
| `c` | Copy selected files, or the hovered file if nothing is selected |
| `x` | Cut selected files, or the hovered file if nothing is selected |
| `v` | Paste files from the Windows file clipboard into the current directory |
| `Alt + A` | Archive selected files, or the hovered file if nothing is selected |
| `Alt + E` | Extract selected archives, or the hovered file if nothing is selected |

## Notes

- This plugin is Windows-only.
- `cut` followed by `paste` moves files and clears the clipboard after a successful move.
- `archive` and `extract` require 7-Zip. If 7-Zip is installed in a custom path, set `YAZI_WINDOWS_CLIPBOARD_7Z` to the full path of `7z.exe`.
- Archive output uses Windows-style conflict names such as `example - Copy.zip`.
- Extract output is written to a same-name directory and also uses Windows-style conflict names.
- Pasting files into apps such as QQ, GPT pages, and browser upload fields depends on whether the target app accepts Windows file clipboard data.
- The bundled PowerShell scripts are part of the plugin and are called by `main.lua`; no separate PowerShell profile setup is required.

## License

MIT

---

# windows-clipboard.yazi 中文说明

在 Yazi 中调用 Windows 原生文件剪贴板。

`windows-clipboard.yazi` 可以让 Yazi 像资源管理器一样复制、剪切、粘贴文件，并通过 Windows 工具完成压缩和解压。复制后的文件可以直接粘贴到资源管理器、QQ、浏览器上传框、GPT 页面等支持 Windows 文件剪贴板的应用里。

## 功能

- 复制选中文件；如果没有选中项，则复制当前悬停项。
- 剪切选中文件；如果没有选中项，则剪切当前悬停项。
- 从 Windows 文件剪贴板粘贴文件到当前 Yazi 目录。
- 将选中文件压缩为 `.zip`。
- 将选中的压缩包解压到当前 Yazi 目录。
- 通过 `Preferred DropEffect` 保留 Windows 的复制 / 剪切语义。
- 目标目录已有同名文件时，自动使用英文 Windows 风格重命名：
  - `example - Copy.txt`
  - `example - Copy (2).txt`
  - `Folder - Copy`
- PowerShell 输出由插件捕获，失败时通过 Yazi 通知显示。

## 环境要求

- Windows
- Yazi 26.5.6 或更新版本
- PowerShell 7，并且命令名为 `pwsh`
- 7-Zip，用于压缩和解压。插件调用的是 7-Zip CLI；Yazi 本身不提供这些压缩 / 解压操作。

7-Zip 的检测顺序：

1. `YAZI_WINDOWS_CLIPBOARD_7Z`
2. `PATH` 中的 `7z.exe`
3. 常见安装路径，例如 `C:\Program Files\7-Zip\7z.exe`

## 安装

### 推荐方式

```powershell
ya pkg add Hh20070324/windows-clipboard.yazi
```

然后在 `keymap.toml` 中加入快捷键：

```toml
[mgr]
prepend_keymap = [
    { on = "c", run = "plugin windows-clipboard -- copy",  desc = "Copy files to Windows clipboard" },
    { on = "x", run = "plugin windows-clipboard -- cut",   desc = "Cut files to Windows clipboard" },
    { on = "v", run = "plugin windows-clipboard -- paste", desc = "Paste files from Windows clipboard" },
    { on = "<A-a>", run = "plugin windows-clipboard -- archive", desc = "Archive selected files" },
    { on = "<A-e>", run = "plugin windows-clipboard -- extract", desc = "Extract selected archives" },
]
```

### 手动本地安装

将整个插件目录复制到：

```text
%APPDATA%\yazi\config\plugins\windows-clipboard.yazi
```

然后把上面的快捷键配置加入 `keymap.toml`。

## 使用

| 快捷键 | 行为 |
|--------|------|
| `c` | 复制选中文件；没有选中项时复制悬停项 |
| `x` | 剪切选中文件；没有选中项时剪切悬停项 |
| `v` | 从 Windows 文件剪贴板粘贴到当前目录 |
| `Alt + A` | 压缩选中文件；没有选中项时压缩悬停项 |
| `Alt + E` | 解压选中的压缩包；没有选中项时解压悬停项 |

## 注意事项

- 该插件仅支持 Windows。
- `x` 剪切后再 `v` 粘贴会移动文件；移动成功后会清空剪贴板，避免重复移动。
- `archive` 和 `extract` 需要 7-Zip。如果 7-Zip 安装在自定义路径，请将 `YAZI_WINDOWS_CLIPBOARD_7Z` 设置为 `7z.exe` 的完整路径。
- 压缩输出使用 Windows 风格冲突命名，例如 `example - Copy.zip`。
- 解压输出会进入同名文件夹，并同样使用 Windows 风格冲突命名。
- 能否粘贴到 QQ、GPT 页面、浏览器上传框等应用，取决于目标应用是否支持 Windows 文件剪贴板。
- PowerShell helper 已经打包在插件目录里，不需要额外修改 PowerShell Profile。

## 许可证

MIT
