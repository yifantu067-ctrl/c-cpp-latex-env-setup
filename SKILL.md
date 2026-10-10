---
name: c-cpp-latex-env-setup
description: Set up one-click build and debug for C and C++ (MSVC) and LaTeX (MiKTeX or TeX Live) on Windows, auto-detecting VS and TeX and writing F5 and Ctrl+Alt+B configs, with zero-install guidance. 自动探测并配置 C/C++ 与 LaTeX 一键编译调试环境，支持零基础安装。Use when creating a C/C++ or LaTeX project or fixing the toolchain. 不用于其他语言（如 Python/Java）。
---

# C / C++ / LaTeX 环境配置

在目标项目目录写入一键编译调试配置。**不写死本机路径**：VS 用 `vswhere` 自动定位，TeX 发行版自动识别，换机器/换盘符/换 VS 版本都能用。

适用：Windows；C/C++ 用 MSVC（VS2022 及以后）；LaTeX 用 xelatex（中文）。跨平台 g++/clang 不在本 skill 范围。

**国内版 Trae 适用性**：`.vscode/` 配置通用（Trae 是 VS Code 内核），**编译、运行、写代码全程离线**。装扩展时 Trae 国内版市场走国内镜像（`api.trae.com.cn` / `open-vsx.trae.com.cn`），**无需翻墙**；唯一可能需代理的是 clangd / CodeLLDB 首次启动从 GitHub 下二进制。

**English**: see [README.en.md](README.en.md) and the full [English install guide](references/install-guide.en.md). Outside mainland China everything is direct — the VS Code Marketplace or Open VSX installs the extensions normally, and clangd / CodeLLDB fetch their binaries from GitHub Releases without a proxy. Add `-Lang en` to the script for English terminal output.

## 零基础？照这个走

即使目标电脑**连编译器都没有**，本 skill 也能一步步带到跑通：

1. 先跑 `-Guide`（**不需要** `-Target`），按终端里 5 步提示依次安装；国际用户加 `-Lang en` 得到英文提示
2. 完整逐步说明见 `references/install-guide.md`（中文）或 `references/install-guide.en.md`（English）：含 winget 自动安装命令、下载链接、安装时勾选项、每步验证方法
3. 装完再带 `-Target` 跑一次，自检逐项给出 `OK/WARN/FAIL`
4. 复制 `assets/samples/hello.c` 打开按 F5 验证

关键：脚本检测到缺少 VS / MiKTeX / 扩展时，会**直接在终端打印安装命令和下载地址**，而不是只丢一句"缺少"。

## skill 结构

```
c-cpp-latex-env-setup\
├── SKILL.md                        # 本文件：说明 + 踩坑 + 维护约定
├── README.md / README.en.md        # 仓库首页说明（中文 / English）
├── scripts\new-project.ps1         # 自检 + 一键写入配置（-Guide / -CheckOnly / -Lang）
├── references\install-guide.md     # 零基础逐步安装指南（中文）
├── references\install-guide.en.md  # Zero-basis install guide (English)
└── assets\
    ├── build.ps1                # 写入项目：MSVC 编译脚本（单文件 / 多文件）
    ├── tasks.json               # 写入 .vscode：F5 前的编译任务
    ├── launch.json              # 写入 .vscode：CodeLLDB 调试
    ├── settings.json            # 写入 .vscode：LaTeX Workshop + clangd
    └── samples\                 # 示例源码，可复制到项目做冒烟测试
        ├── hello.c              # 纯 C 示例
        ├── hello.cpp            # C++ 示例
        └── sample.tex           # 中文 LaTeX 示例
```

## 一键套用

```powershell
# 零基础（电脑上什么都没装）：先看逐步安装指引
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\new-project.ps1" -Guide

# 全流程：自检 + 写入配置
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\new-project.ps1" -Target "<新项目绝对路径>"

# 只做环境自检，不写文件
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\new-project.ps1" -Target "." -CheckOnly

# 英文输出（国际用户）
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\new-project.ps1" -Target "<新项目绝对路径>" -Lang en
```

写入时脚本会：自检并彩色标注 `OK/WARN/FAIL`（缺什么就打印对应安装命令）→ 复制 `assets/build.ps1` 到项目根 → 复制 `tasks.json`、`launch.json`、`settings.json` 到 `.vscode/` → 把 MSVC 的 cl.exe 路径注入 `clangd.arguments`（消除头文件红波浪线）。

## 脚本自动探测的内容

- **Visual Studio**：`%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe` 找最新含 C++ 工具的实例；找不到则回退常见路径
- **MSVC**：`VC\Tools\MSVC\*\bin\Hostx64\x64\cl.exe`
- **TeX**：PATH 上的 `xelatex`/`pdflatex`/`latexmk`，并判定 MiKTeX 还是 TeX Live
- **扩展**：在 `.trae-cn`/`.trae`/`.vscode` 的 extensions 目录里查 clangd、CodeLLDB、LaTeX Workshop

## 使用方式

- **C / C++**：打开 `.c` 或 `.cpp` 按 **F5**（自动编译 + 调试）
- **LaTeX**：`.tex` 按 **Ctrl+Alt+B** 编译、**Ctrl+Alt+V** 预览（保存即自动编译）

编译产物统一放进项目下的 `build\`（`hello.exe` / `hello.obj` / `hello.pdb` / `vc140.pdb` / `hello.ilk`），**项目根只留源码与配置**。想清理直接删掉 `build\` 文件夹即可，不要手动删根目录里的 `build.ps1`（那是编译脚本，不是产物）。

## C 与 C++ 说明

- MSVC 的 `cl.exe` **按扩展名识别语言**：`.c` 当 C 编，`.cpp` 当 C++ 编，无需额外配置
- `build.ps1` 里的 `/EHsc` 是 C++ 专用标志，对 `.c` 会被 MSVC **静默忽略**，不会报错
- 常识限制：C 里不能用 `iostream` 等 C++ 头文件；C 用 `stdio.h`

## 多文件编译

默认只编译当前文件（`F5` 传入 `${relativeFile}`）。同一目录有多个源文件需要一起链接时，用 `-All`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\build.ps1" -Source ".\main.cpp" -All
```

`-All` 会编译该目录内全部 `.c/.cpp/.cc/.cxx`，再链接成以 `-Source` 文件同名的 `.exe`。

注意：`-All` 编译的是**整个目录**的源文件。若目录里还放有带 `main` 的其它示例（如 `hello.c`），会报 `LNK2005 多重定义`——先移走或删掉多余文件。

## Troubleshooting（按踩过的坑逐条列出）

| # | 症状 | 原因 | 解法 |
|---|------|------|------|
| 1 | 报"文件不存在"，路径被截断 | Windows 用户名含单引号（如 `O'Brien`），绝对路径拼进 PowerShell 命令被解析截断 | 配置里**一律用相对路径**；绝不把绝对路径写进 shell 命令 |
| 2 | `cl` 找不到 | `cl.exe` 不在系统 PATH | `build.ps1` 用 `Enter-VsDevShell` 加载 VS 开发环境；普通终端找不到属正常 |
| 3 | `latexmk` 报错 | latexmk 依赖 Perl，未安装 | 用**纯 xelatex**（不依赖 Perl） |
| 4 | `Cleaning failed` | 旧清理方式与 latexmk 冲突 | `clean.method` 设为 `glob` |
| 5 | 配置不生效 | 目录名不是 `.vscode` | 必须是 **`.vscode`（带点）** 才会被识别 |
| 6 | 找不到编译器 | 用了 StrawberryPerl 自带的旧 `g++` | C/C++ 只用 MSVC，别用该 `g++` |
| 7 | 装完新工具仍不可用 | IDE 未获取到新的 PATH | **重启 IDE**（有时需重启终端） |
| 8 | 无法写入配置文件 | `.vscode` 文件被占用/受保护 | 关闭 IDE 后重跑脚本，或手动把 `assets/` 内容贴上 |
| 9 | C/C++ 头文件红色波浪线 | clangd 未找到 MSVC 头文件 | 脚本已注入 `clangd.arguments = --query-driver=<cl.exe>`，重载窗口生效；无伤大雅可忽略 |
| 10 | MiKTeX 提示 `User/administrator updates out-of-sync` | 用户/管理员更新不同步 | 不影响出 PDF；可管理员运行 MiKTeX Console 更新消除 |
| 11 | 多文件项目报 `LNK2019 unresolved external` | 默认只编译当前文件，其他源文件未参与链接 | 用 `-All` 一次编译目录内所有源文件；或把代码合并为单文件 |
| 12 | winget 命令不存在 | 系统未带「应用安装程序」 | 用 `references/install-guide.md` 里的手动下载方式 |
| 13 | 扩展"安装失败 / 一直转圈" | Trae 国内版市场已指向国内镜像，仍失败多为网络抖动 | 优先在 Trae 内置市场搜装（走 `api.trae.com.cn` / `open-vsx.trae.com.cn`，**无需翻墙**）；再不行从 Open VSX 下 `.vsix` 用「Install from VSIX...」离线装。详见 `references/install-guide.md` 步骤 3 |
| 14 | clangd 装上但不补全 | 扩展首启要从 **GitHub Releases** 下 clangd 二进制，国内常失败（这才是主要"翻墙点"） | 手动下载 `clangd-windows-*.zip`，解压后用 `settings.json` 的 `clangd.path` 指向 `clangd.exe`；或配代理重试 |
| 15 | CodeLLDB 装上仍无法 F5 调试 | 其 lldb 平台二进制同样来自 GitHub Releases，下载失败 | 配代理重试后重启；确认 `launch.json` 的 `type` 为 `lldb` |

## 手工 fallback

脚本不可用时：把 `assets/build.ps1` 复制到项目根；把 `assets/` 下 `tasks.json`、`launch.json`、`settings.json` 复制到项目的 `.vscode/`。

## 维护约定（改脚本时必看）

- `.ps1` 里**禁用全角引号** `“ ”`：PowerShell 会把它当字符串定界符，导致 "Unexpected token" 解析错误。改用 `[ ]` 或 `「 」`
- `.ps1` 里**禁用绝对路径拼进命令**：用户名含单引号会被截断，一切用相对路径或变量传参

## 验证

改动源文件后按 F5 / Ctrl+Alt+B，确认生成 `.exe` / `.pdf` 即成功。
快速冒烟测试：把 `assets/samples/hello.c`（或 `hello.cpp`）复制到项目根按 F5；把 `sample.tex` 复制过去按 Ctrl+Alt+B。