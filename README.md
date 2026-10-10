[中文](README.md) | [English](README.en.md)

# c-cpp-python-latex-env-setup

一个 **TRAE / VS Code 技能（Skill）**：在 Windows 上一键配置 **C / C++（MSVC）**、**Python** 与 **LaTeX（MiKTeX / TeX Live）** 的编译调试环境。

新建项目时自动探测本机工具链，把 `F5`（编译/运行 + 调试）和 `Ctrl+Alt+B`（编译 PDF）的配置一次性写好；电脑上什么都没装时，也能一步步带着装完。

---

## 它能解决什么

- **每建一个新项目都要重新配置解释器？** 一条命令写好 `.vscode/` 配置，之后新建项目直接复用。
- **电脑上还没装编译器？** 加 `-Guide` 参数，终端里给出每一步的安装命令、下载地址和验证方法。
- **配置写死路径、换机器就失效？** 用 `vswhere` 自动定位 Visual Studio，自动识别 TeX 发行版、自动探测 Python 解释器，换盘符 / 换版本都能用。
- **C/C++ 头文件一堆红色波浪线？** 自动把 MSVC 的 `cl.exe` 路径注入 clangd 的 `--query-driver`，并把 Python 解释器写进 `python.defaultInterpreterPath`。
- **多文件项目报未定义符号？** `build.ps1 -All` 一次编译整个目录的源文件再链接。

## 环境要求

| 项目 | 要求 |
|---|---|
| 系统 | Windows 10 / 11 |
| 编辑器 | Trae 或 VS Code（**Trae 国内版同样适用**，编译运行全程离线） |
| C / C++ | Visual Studio 2022，安装时勾选工作负载 **使用 C++ 的桌面开发** |
| Python（可选） | 官方 CPython 3.x，安装时勾选 **Add python.exe to PATH** |
| LaTeX（可选） | MiKTeX 或 TeX Live，需带 `xelatex` |
| 扩展 | clangd、CodeLLDB、LaTeX Workshop、Python（脚本会检测并给出安装提示） |

## 快速开始

### 1. 安装这个 skill

克隆到 Trae 的全局 skills 目录（VS Code 用户把 `.trae-cn` 换成 `.vscode` 或对应目录即可）：

```powershell
git clone https://github.com/yifantu067-ctrl/c-cpp-python-latex-env-setup.git "$env:USERPROFILE\.trae-cn\skills\c-cpp-python-latex-env-setup"
```

> 不想用 git：直接下载 ZIP 解压，把 `c-cpp-python-latex-env-setup` 整个文件夹放进 `%USERPROFILE%\.trae-cn\skills\`。

### 2. 零基础先看安装指引

如果电脑上连编译器都没有，先跑 `-Guide`（不需要 `-Target`）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.trae-cn\skills\c-cpp-python-latex-env-setup\scripts\new-project.ps1" -Guide
```

按终端里的 6 步提示依次安装 Visual Studio、MiKTeX、Python 和编辑器扩展。完整说明见 [references/install-guide.md](references/install-guide.md)（英文版：[install-guide.en.md](references/install-guide.en.md)）。

### 3. 给项目写入配置

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.trae-cn\skills\c-cpp-python-latex-env-setup\scripts\new-project.ps1" -Target "D:\你的项目目录"
```

脚本会先把本机环境自检一遍（彩色 `OK / WARN / FAIL`，缺什么就打印安装命令），然后写入：

- `build.ps1` → 项目根目录
- `tasks.json`、`launch.json`、`settings.json` → 项目 `.vscode/`

只想自检、不写文件：加 `-CheckOnly`。
英文终端输出：加 `-Lang en`（默认中文）。

### 4. 验证跑通

把 `assets\samples\hello.c` 复制到项目根目录，打开后按 **F5**，终端应输出 `Hello World!`。
Python 把 `hello.py` 复制过去按 **F5**；LaTeX 把 `sample.tex` 复制过去按 **Ctrl+Alt+B**，应生成 `sample.pdf`。

## 使用方式

| 文件类型 | 操作 | 效果 |
|---|---|---|
| `.c` / `.cpp` | **F5** | 自动编译并进入调试 |
| `.py` | **F5** | 用探测到的 Python 解释器运行并调试（`debugpy`） |
| 多个源文件 | `build.ps1 -Source xx.cpp -All` | 编译同目录全部 `.c/.cpp/.cc/.cxx` 再统一链接 |
| `.tex` | **Ctrl+Alt+B** / **Ctrl+Alt+V** | 编译出 PDF / 预览（保存即自动编译） |

> 注意：`-All` 编译的是**整个目录**的源文件。若目录里还放有带 `main` 的其它示例（如 `hello.c`），会报 `LNK2005 多重定义`，先移走或删掉多余文件。

编译产物统一放在项目下的 **`build\`** 文件夹里（`.exe` / `.obj` / `.pdb` / `.ilk`），项目根目录只保留源码和配置，不会越用越乱。想清理直接删掉 `build\` 即可。

## 目录结构

```
c-cpp-python-latex-env-setup/
├── SKILL.md                        # 技能入口：说明 + 踩坑表 + 维护约定
├── README.md / README.en.md        # 仓库首页说明（中文 / English）
├── scripts/
│   └── new-project.ps1             # 环境自检 + 一键写入配置（-Guide / -CheckOnly / -Lang）
├── references/
│   ├── install-guide.md            # 零基础逐步安装指南（中文）
│   └── install-guide.en.md         # Zero-basis install guide (English)
└── assets/
    ├── build.ps1                   # 写入项目：MSVC 编译脚本（单文件 / 多文件）
    ├── tasks.json                  # 写入 .vscode：F5 前的 C/C++ 编译任务
    ├── launch.json                 # 写入 .vscode：CodeLLDB（C/C++）+ debugpy（Python）
    ├── settings.json               # 写入 .vscode：LaTeX Workshop + clangd + Python 解释器
    └── samples/                    # 冒烟测试用示例
        ├── hello.c
        ├── hello.cpp
        ├── hello.py
        └── sample.tex
```

## 常见问题

| 症状 | 原因 / 解法 |
|---|---|
| 普通终端里 `cl` 找不到 | 正常，`cl.exe` 不在系统 PATH，脚本会自动进入 VS 开发环境 |
| `latexmk` 报错 | `latexmk` 依赖 Perl，本技能改用**纯 xelatex** |
| LaTeX 中文报错 | 中文必须用 `xelatex`（已默认），不要改成 pdflatex |
| C/C++ 头文件红色波浪线 | 脚本已注入 `--query-driver`，重载窗口即可；也可忽略，不影响编译运行 |
| Python 按 F5 提示找不到解释器 | 装 Python 时未勾选 **Add python.exe to PATH**；重装勾选，或重启编辑器让脚本写入的 `python.defaultInterpreterPath` 生效 |
| Python 无法 F5 调试 | `launch.json` 的 `type` 为 `debugpy`，需要 **Python 扩展**（含 debugpy），脚本会检测并提示安装 |
| 装完新工具仍不可用 | **重启编辑器**，让新的 PATH 生效 |
| 扩展装不上 / 一直转圈 | Trae 国内版市场走国内镜像（`api.trae.com.cn` / `open-vsx.trae.com.cn`），**无需翻墙**；仍失败可从 Open VSX 下载 `.vsix` 离线安装 |
| 扩展装上了但补全/F5 不通 | clangd、CodeLLDB 首次启动要从 GitHub Releases 下二进制，可手动放置或配代理 |
| 提示 `User/administrator updates out-of-sync` | MiKTeX 用户/管理员更新不同步，不影响出 PDF |

完整排障表见 [SKILL.md](SKILL.md)，安装细节见 [references/install-guide.md](references/install-guide.md)。

## 许可

本项目采用 [MIT License](LICENSE)，可自由使用、修改和分发。