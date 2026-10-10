# 零基础安装指南（从一台没有任何编译器的电脑开始）

适用：Windows 10 / 11。所有安装**只需做一次**，之后新建项目直接套用配置即可。
本文按顺序照做，每一步末尾都有「怎么验证成功」。全程约 4 次安装。

> 熟练后可用脚本一行看指引：
> `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\new-project.ps1" -Guide`

---

## 步骤 0：确认前提

- 系统是 Windows 10 / 11
- 能联网
- 有管理员权限（装 Visual Studio 会弹 UAC，点是）
- 已安装编辑器（Trae 或 VS Code）。没装先装编辑器，本 skill 的配置靠它的 `.vscode` 生效。

---

## 步骤 1：安装 Visual Studio 2022（提供 C / C++ 编译器）

**作用**：提供 `cl.exe`（MSVC），C 和 C++ 都靠它编译。

**方式 A · 自动（推荐，Win10/11 自带 winget）**
在 PowerShell 里执行：

```powershell
winget install Microsoft.VisualStudio.2022.Community --override "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"
```

**方式 B · 手动**
1. 打开 https://visualstudio.microsoft.com/vs/community/ 下载 Community 版
2. 运行安装器，在「工作负载」页**务必勾选**：**使用 C++ 的桌面开发**
3. 右侧「安装详细信息」保持默认即可，点安装

**验证**
- 安装目录下应存在 `VC\Tools\MSVC\<版本>\bin\Hostx64\x64\cl.exe`
- 或在「开始菜单」找到 **Developer PowerShell for VS 2022**，打开后输入 `cl`，能看到版本信息

> 注意：在**普通** PowerShell 里输入 `cl` 通常提示找不到——这是正常的。本 skill 的脚本会自动进入 VS 开发环境，无需你手动配 PATH。

---

## 步骤 2：安装 MiKTeX（提供 LaTeX 引擎）

**作用**：提供 `xelatex`，用于编译中文 LaTeX（`.tex` → `.pdf`）。

**方式 A · 自动**

```powershell
winget install MiKTeX.MiKTeX
```

**方式 B · 手动**
1. 打开 https://miktex.org/download 下载安装器
2. 安装时选择 **Install for me only**（当前用户）即可，一路默认

**验证**
- **重开一个终端**（重要：PATH 要新开才生效），执行 `xelatex --version`，能看到版本信息

> 若不需要 LaTeX，可跳过本步，只用 C/C++ 功能。

---

## 步骤 3：安装 3 个编辑器扩展

在 Trae / VS Code 的**扩展市场**（左侧方块图标）搜索并安装：

| 扩展名 | 安装 ID | 作用 |
|---|---|---|
| clangd | `llvm-vs-code-extensions.vscode-clangd` | C/C++ 补全、错误提示 |
| CodeLLDB | `vadimcn.vscode-lldb` | F5 调试（launch.json 依赖它） |
| LaTeX Workshop | `james-yu.latex-workshop` | LaTeX 编译、PDF 预览 |

**命令行安装**（编辑器已加入 PATH 时）：

```powershell
code --install-extension llvm-vs-code-extensions.vscode-clangd
code --install-extension vadimcn.vscode-lldb
code --install-extension james-yu.latex-workshop
```

**验证**：扩展列表里能看到这三个已启用。

### 扩展安装失败怎么办（国内网络重点看）

**结论先说**：Trae 国内版在编辑器里搜装扩展，市场走的是**国内域名**（`api.trae.com.cn`、`open-vsx.trae.com.cn`），**不需要翻墙**。
真正可能"需要代理"的环节，是扩展**首次启动时自己去 GitHub Releases 下二进制**（见第 4 条）。

按下面顺序试：

**1) 优先在 Trae 内置市场搜装**（国内直连）
点左侧扩展图标，搜 clangd / CodeLLDB / LaTeX Workshop 安装即可。

**2) 命令行安装**（编辑器 CLI 已加入 PATH 时）

```powershell
code --install-extension llvm-vs-code-extensions.vscode-clangd
code --install-extension vadimcn.vscode-lldb
code --install-extension james-yu.latex-workshop
```

**3) 离线 VSIX 安装**（市场、命令行都失败时）
Trae 的市场源是 **Open VSX**，优先从这里下 `.vsix`：
- clangd：https://open-vsx.org/extension/llvm-vs-code-extensions/vscode-clangd
- CodeLLDB：https://open-vsx.org/extension/vadimcn/vscode-lldb
- LaTeX Workshop：https://open-vsx.org/extension/james-yu/latex-workshop

装法：编辑器内扩展面板右上 `...` → **Install from VSIX...** → 选刚下载的文件
（或命令行 `code --install-extension <文件路径>.vsix`）

**4) 装上了但功能不通 —— 这才是国内网络的主要卡点**
这两个扩展首次运行会去 **GitHub Releases** 下载自己的二进制，国内常超时失败：
- **clangd**：下载 clangd 服务端二进制。可手动下载 `clangd-windows-*.zip`，解压后在 `settings.json` 里用 `clangd.path` 指向 `clangd.exe`
- **CodeLLDB**：下载 lldb 平台二进制。可配代理重试，或手动放置

需要代理时：设系统环境变量 `HTTP_PROXY`、`HTTPS_PROXY`（例如 `http://127.0.0.1:7890`），然后**重启编辑器**。

**验证**：重启编辑器后扩展显示已启用；C/C++ 有补全、按 F5 能进调试。

---

## 步骤 4：写入项目配置

1. 在项目文件夹里打开终端
2. 执行（把 `<skill目录>`、`<项目目录>` 换成实际路径）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\new-project.ps1" -Target "<项目目录>"
```

脚本会自检并写入 `build.ps1` + `.vscode\` 三个配置。
**验证**：看到自检全为 `[OK]`、末尾提示「已写入配置」。若有 `[FAIL]/[WARN]`，按其提示回到对应步骤。

---

## 步骤 5：验证端到端跑通

1. 把 `<skill目录>\assets\samples\hello.c` 复制到项目根
2. 用编辑器打开该项目文件夹，打开 `hello.c`，按 **F5**
3. 终端应输出 `Hello World!`

LaTeX：把 `sample.tex` 复制过去，按 **Ctrl+Alt+B**，应生成 `sample.pdf`。

---

## 常见卡点

| 卡点 | 处理 |
|---|---|
| 装完工具仍不可用 | **重启编辑器**（有时连终端一起重开），让 PATH 刷新 |
| `winget` 不存在 | 用上面的「方式 B 手动」，或到 Microsoft Store 更新「应用安装程序」 |
| `cl` 在普通终端找不到 | 正常，脚本会自动进 VS 环境；不要在普通终端手敲 `cl` |
| C/C++ 头文件有红色波浪线 | 脚本已注入 `--query-driver`；重载窗口即可，也可忽略，不影响编译运行 |
| MiKTeX 提示 `User/administrator updates out-of-sync` | 不影响出 PDF；可管理员运行 MiKTeX Console 更新 |
| 中文 LaTeX 报错 | 必须用 `xelatex`（本 skill 已默认），不要改成 pdflatex |
| 路径报「文件不存在」 | 路径含特殊字符/单引号时，用相对路径，别把绝对路径拼进命令 |
| 编译后目录里多出一堆文件 | 正常，都是 MSVC 产物（`.exe/.obj/.pdb/.ilk`），且已统一放在 `build\` 下；删掉 `build\` 即可清理 |