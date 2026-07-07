This plugin was generated and implemented by Codex for Hh20070324.

# windows-clipboard.yazi

Use the Windows native file clipboard from Yazi.

`windows-clipboard.yazi` lets Yazi copy, cut, and paste files through the same Windows file clipboard used by File Explorer, QQ, browser upload fields, GPT pages, and other Windows apps.

## Features

- Copy selected files, or the hovered file if nothing is selected.
- Cut selected files, or the hovered file if nothing is selected.
- Paste files from the Windows file clipboard into the current Yazi directory.
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

## Installation

### Recommended, after publishing to GitHub

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

## Notes

- This plugin is Windows-only.
- `cut` followed by `paste` moves files and clears the clipboard after a successful move.
- Pasting files into apps such as QQ, GPT pages, and browser upload fields depends on whether the target app accepts Windows file clipboard data.
- The bundled PowerShell scripts are part of the plugin and are called by `main.lua`; no separate PowerShell profile setup is required.

## License

MIT

---

# windows-clipboard.yazi 中文说明

在 Yazi 中调用 Windows 原生文件剪贴板。

`windows-clipboard.yazi` 可以让 Yazi 像资源管理器一样复制、剪切、粘贴文件。复制后的文件可以直接粘贴到资源管理器、QQ、浏览器上传框、GPT 页面等支持 Windows 文件剪贴板的应用里。

## 功能

- 复制选中文件；如果没有选中项，则复制当前悬停项。
- 剪切选中文件；如果没有选中项，则剪切当前悬停项。
- 从 Windows 文件剪贴板粘贴文件到当前 Yazi 目录。
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

## 安装

### 推荐方式：发布到 GitHub 后

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

## 注意事项

- 该插件仅支持 Windows。
- `x` 剪切后再 `v` 粘贴会移动文件；移动成功后会清空剪贴板，避免重复移动。
- 能否粘贴到 QQ、GPT 页面、浏览器上传框等应用，取决于目标应用是否支持 Windows 文件剪贴板。
- PowerShell helper 已经打包在插件目录里，不需要额外修改 PowerShell Profile。

## 许可证

MIT
