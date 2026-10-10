# 探测本机 C/C++/Python/LaTeX 环境并把一键编译调试配置写入目标项目目录
# Detect the local C/C++/Python/LaTeX toolchain and write the build & debug config into a project folder.
# 零基础用户：先跑 -Guide 看逐步安装指引，装完再带 -Target 跑一次
# Zero-basis users: run -Guide first, then re-run with -Target after installing.
param(
    [string]$Target,
    [switch]$CheckOnly,                        # 只做环境自检，不写文件 / self-check only, write nothing
    [switch]$Guide,                            # 打印逐步安装指引后退出（无需 -Target） / print install guide and exit
    [ValidateSet('zh', 'en')][string]$Lang = 'zh'   # 输出语言 / output language
)

$ErrorActionPreference = 'Stop'

# ---------- 文案表 / message table ----------
$M = @{
    zh = @{
        Checking        = '==== 环境自检 ===='
        VsFound         = 'Visual Studio: {0}'
        ClFound         = 'MSVC cl.exe: {0}'
        ClMissing       = '找到 VS 但缺少 MSVC 编译器'
        ClMissingHint   = '请打开 Visual Studio Installer -> 修改 -> 勾选 [使用 C++ 的桌面开发]'
        VsMissing       = '未找到 Visual Studio（C/C++ 无法编译）'
        VsAuto          = '自动安装: winget install Microsoft.VisualStudio.2022.Community --override '
        VsAutoCont      = '          "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"'
        VsManual        = '手动安装: https://visualstudio.microsoft.com/vs/community/'
        VsManualHint    = '安装时务必勾选工作负载 [使用 C++ 的桌面开发]'
        TexMissing      = '未找到 LaTeX 引擎（LaTeX 无法编译）'
        TexAuto         = '自动安装: winget install MiKTeX.MiKTeX'
        TexManual       = '手动安装: https://miktex.org/download'
        TexSkip         = '仅用 C/C++ 可忽略此项'
        TexDistro       = 'TeX 发行版: {0}'
        TexEngine       = '引擎 {0} : {1}'
        XelatexMissing  = '未找到 xelatex（中文推荐）'
        XelatexHint     = '可把 settings.json 的 recipe 改为 pdflatex，或安装含 xelatex 的发行版'
        ExtInstalled    = '扩展已装: {0}'
        ExtMissing      = '缺少扩展: {0}'
        ExtHint1        = 'Trae 内置市场搜装即可（国内镜像，无需翻墙），或: code --install-extension {0}'
        ExtHint2        = '若装不上: https://open-vsx.org/extension/{0}/{1} 下载 .vsix 后 Install from VSIX...'
        CheckDone       = '==== 自检结束（未写入文件）===='
        NoTarget        = '缺少 -Target 参数（要写入配置的项目目录）'
        NoTargetHint    = '想看零基础安装指引，请加 -Guide（无需 -Target）'
        Written         = '已写入配置: {0}'
        NextStep        = '下一步: 放入 .c/.cpp 或 .py 按 F5；.tex 按 Ctrl+Alt+B（C/C++ 多文件加 -All）'
        Samples         = '示例可复制 assets\samples\ 下的 hello.c / hello.cpp / hello.py / sample.tex'
        PyFound         = 'Python: {0}'
        PyVer           = 'Python 版本: {0}'
        PyMissing       = '未找到 Python（Python 无法运行）'
        PyAuto          = '自动安装: winget install Python.Python.3.13'
        PyManual        = '手动安装: https://www.python.org/downloads/ （安装时务必勾选 Add python.exe to PATH）'
        PySkip          = '仅用 C/C++/LaTeX 可忽略此项'
        D_clangd        = 'clangd（C/C++ 补全/报错）'
        D_lldb          = 'CodeLLDB（C/C++ F5 调试）'
        D_latex         = 'LaTeX Workshop（编译/预览）'
        D_py            = 'Python（F5 调试 Python）'
        L_cpp           = 'C/C++ 编译并调试 (F5)'
        L_py            = 'Python 运行并调试 (F5)'
    }
    en = @{
        Checking        = '==== Environment self-check ===='
        VsFound         = 'Visual Studio: {0}'
        ClFound         = 'MSVC cl.exe: {0}'
        ClMissing       = 'Visual Studio found but the MSVC compiler is missing'
        ClMissingHint   = 'Open Visual Studio Installer -> Modify -> check [Desktop development with C++]'
        VsMissing       = 'Visual Studio not found (C/C++ cannot be compiled)'
        VsAuto          = 'Automatic: winget install Microsoft.VisualStudio.2022.Community --override '
        VsAutoCont      = '           "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"'
        VsManual        = 'Manual: https://visualstudio.microsoft.com/vs/community/'
        VsManualHint    = 'During install, make sure the [Desktop development with C++] workload is checked'
        TexMissing      = 'No LaTeX engine found (LaTeX cannot be compiled)'
        TexAuto         = 'Automatic: winget install MiKTeX.MiKTeX'
        TexManual       = 'Manual: https://miktex.org/download'
        TexSkip         = 'Ignore this if you only need C/C++'
        TexDistro       = 'TeX distribution: {0}'
        TexEngine       = 'Engine {0} : {1}'
        XelatexMissing  = 'xelatex not found (recommended, required for Chinese)'
        XelatexHint     = 'Change the recipe in settings.json to pdflatex, or install a distribution that ships xelatex'
        ExtInstalled    = 'Extension installed: {0}'
        ExtMissing      = 'Missing extension: {0}'
        ExtHint1        = 'Install it from the editor marketplace, or: code --install-extension {0}'
        ExtHint2        = 'If that fails: https://open-vsx.org/extension/{0}/{1} download the .vsix and use Install from VSIX...'
        CheckDone       = '==== Self-check finished (no files written) ===='
        NoTarget        = 'Missing -Target parameter (the project folder to write config into)'
        NoTargetHint    = 'For the zero-basis install guide, add -Guide (no -Target needed)'
        Written         = 'Config written: {0}'
        NextStep        = 'Next: add a .c/.cpp or .py file and press F5; press Ctrl+Alt+B for .tex (add -All for multi-file C/C++)'
        Samples         = 'Samples: copy hello.c / hello.cpp / hello.py / sample.tex from assets\samples\'
        PyFound         = 'Python: {0}'
        PyVer           = 'Python version: {0}'
        PyMissing       = 'Python not found (Python cannot run)'
        PyAuto          = 'Automatic: winget install Python.Python.3.13'
        PyManual        = 'Manual: https://www.python.org/downloads/ (check "Add python.exe to PATH" during install)'
        PySkip          = 'Ignore this if you only need C/C++ or LaTeX'
        D_clangd        = 'clangd (C/C++ completion and diagnostics)'
        D_lldb          = 'CodeLLDB (C/C++ F5 debugging)'
        D_latex         = 'LaTeX Workshop (build and PDF preview)'
        D_py            = 'Python (F5 debugging for Python)'
        L_cpp           = 'C/C++ build & debug (F5)'
        L_py            = 'Python run & debug (F5)'
    }
}
$T = $M[$Lang]

$G = @{
    zh = @(
        @{ c = 'Cyan';   t = '========== 零基础逐步安装指引（从零到能跑）==========' }
        @{ c = '';       t = '全部安装只需做一次，之后新建项目直接复用。' }
        @{ c = 'Yellow'; t = '步骤 1  安装 Visual Studio 2022（提供 C/C++ 编译器 cl.exe）' }
        @{ c = '';       t = '  自动: winget install Microsoft.VisualStudio.2022.Community --override ' }
        @{ c = 'DarkGray'; t = '        "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"' }
        @{ c = '';       t = '  手动: 下载 https://visualstudio.microsoft.com/vs/community/' }
        @{ c = 'DarkGray'; t = '        安装时务必勾选工作负载 [使用 C++ 的桌面开发]' }
        @{ c = '';       t = '  验证: 开始菜单打开 Developer PowerShell for VS 2022，输入 cl 能看到版本' }
        @{ c = 'DarkGray'; t = '        普通 PowerShell 里找不到 cl 属正常，脚本会自动进 VS 环境' }
        @{ c = 'Yellow'; t = '步骤 2  安装 MiKTeX（提供 LaTeX 引擎 xelatex）' }
        @{ c = '';       t = '  自动: winget install MiKTeX.MiKTeX' }
        @{ c = '';       t = '  手动: 下载 https://miktex.org/download （Install for me only 即可）' }
        @{ c = '';       t = '  验证: 重开终端执行 xelatex --version' }
        @{ c = 'DarkGray'; t = '        不需要 LaTeX 可跳过此步，只用 C/C++' }
        @{ c = 'Yellow'; t = '步骤 3  安装 Python（提供 python.exe，用于 .py 脚本）' }
        @{ c = '';       t = '  自动: winget install Python.Python.3.13' }
        @{ c = '';       t = '  手动: 下载 https://www.python.org/downloads/' }
        @{ c = 'DarkGray'; t = '        安装时务必勾选 Add python.exe to PATH' }
        @{ c = '';       t = '  验证: 重开终端执行 python --version 能看到版本' }
        @{ c = 'DarkGray'; t = '        不需要 Python 可跳过此步' }
        @{ c = 'Yellow'; t = '步骤 4  安装编辑器扩展（在扩展市场搜索安装）' }
        @{ c = '';       t = '  clangd          ID: llvm-vs-code-extensions.vscode-clangd   （C/C++ 补全报错）' }
        @{ c = '';       t = '  CodeLLDB        ID: vadimcn.vscode-lldb                     （C/C++ F5 调试）' }
        @{ c = '';       t = '  LaTeX Workshop  ID: james-yu.latex-workshop                 （LaTeX 编译预览）' }
        @{ c = '';       t = '  Python          ID: ms-python.python                        （Python 运行调试）' }
        @{ c = 'DarkGray'; t = '        或命令行: code --install-extension <上面的ID>' }
        @{ c = 'DarkGray'; t = '        国内版: 直接在 Trae 内置市场搜装即可（走国内镜像，无需翻墙）' }
        @{ c = 'DarkGray'; t = '        仍装不上: 从 Open VSX 下载 .vsix 后用 Install from VSIX... 离线安装' }
        @{ c = 'Yellow'; t = '步骤 5  写入项目配置' }
        @{ c = '';       t = '  去掉 -Guide，带 -Target 再运行本脚本一次：' }
        @{ c = 'DarkGray'; t = '        ... -File "<skill目录>\scripts\new-project.ps1" -Target "<项目目录>"' }
        @{ c = 'Yellow'; t = '步骤 6  验证' }
        @{ c = '';       t = '  复制 assets\samples\hello.c 到项目根，打开按 F5 -> 输出 Hello World!' }
        @{ c = '';       t = '  复制 assets\samples\hello.py 过去，打开按 F5 -> 运行 Python' }
        @{ c = '';       t = '  复制 assets\samples\sample.tex 过去，按 Ctrl+Alt+B -> 生成 PDF' }
        @{ c = 'DarkGray'; t = '通用提示: 装完任何新工具后请[重启编辑器]，否则可能读不到新的 PATH。' }
        @{ c = 'Cyan';   t = '===================================================' }
    )
    en = @(
        @{ c = 'Cyan';   t = '========== Step-by-step install guide (from zero to running) ==========' }
        @{ c = '';       t = 'Everything is installed once; afterwards new projects just reuse the config.' }
        @{ c = 'Yellow'; t = 'Step 1  Install Visual Studio 2022 (provides the C/C++ compiler cl.exe)' }
        @{ c = '';       t = '  Auto: winget install Microsoft.VisualStudio.2022.Community --override ' }
        @{ c = 'DarkGray'; t = '        "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"' }
        @{ c = '';       t = '  Manual: download https://visualstudio.microsoft.com/vs/community/' }
        @{ c = 'DarkGray'; t = '        During install, make sure to check the [Desktop development with C++] workload' }
        @{ c = '';       t = '  Verify: open Developer PowerShell for VS 2022 from the Start menu and type cl' }
        @{ c = 'DarkGray'; t = '        Not finding cl in a normal PowerShell is expected; the script enters the VS environment for you' }
        @{ c = 'Yellow'; t = 'Step 2  Install MiKTeX (provides the LaTeX engine xelatex)' }
        @{ c = '';       t = '  Auto: winget install MiKTeX.MiKTeX' }
        @{ c = '';       t = '  Manual: download https://miktex.org/download ("Install for me only" is fine)' }
        @{ c = '';       t = '  Verify: open a new terminal and run xelatex --version' }
        @{ c = 'DarkGray'; t = '        Skip this step if you only need C/C++' }
        @{ c = 'Yellow'; t = 'Step 3  Install Python (provides python.exe for .py scripts)' }
        @{ c = '';       t = '  Auto: winget install Python.Python.3.13' }
        @{ c = '';       t = '  Manual: download https://www.python.org/downloads/' }
        @{ c = 'DarkGray'; t = '        During install, make sure to check "Add python.exe to PATH"' }
        @{ c = '';       t = '  Verify: open a new terminal and run python --version' }
        @{ c = 'DarkGray'; t = '        Skip this step if you do not need Python' }
        @{ c = 'Yellow'; t = 'Step 4  Install the editor extensions (search in the marketplace)' }
        @{ c = '';       t = '  clangd          ID: llvm-vs-code-extensions.vscode-clangd   (C/C++ completion and diagnostics)' }
        @{ c = '';       t = '  CodeLLDB        ID: vadimcn.vscode-lldb                     (C/C++ F5 debugging)' }
        @{ c = '';       t = '  LaTeX Workshop  ID: james-yu.latex-workshop                 (LaTeX build and PDF preview)' }
        @{ c = '';       t = '  Python          ID: ms-python.python                        (Python run and debug)' }
        @{ c = 'DarkGray'; t = '        Or from the CLI: code --install-extension <ID>' }
        @{ c = 'DarkGray'; t = '        Marketplace not working: download the .vsix from Open VSX and use Install from VSIX...' }
        @{ c = 'Yellow'; t = 'Step 5  Write the project config' }
        @{ c = '';       t = '  Re-run this script without -Guide, with -Target:' }
        @{ c = 'DarkGray'; t = '        ... -File "<skill-dir>\scripts\new-project.ps1" -Target "<project-dir>"' }
        @{ c = 'Yellow'; t = 'Step 6  Verify' }
        @{ c = '';       t = '  Copy assets\samples\hello.c into the project root, open it and press F5 -> Hello World!' }
        @{ c = '';       t = '  Copy assets\samples\hello.py over, open it and press F5 -> Python runs' }
        @{ c = '';       t = '  Copy assets\samples\sample.tex and press Ctrl+Alt+B -> a PDF is generated' }
        @{ c = 'DarkGray'; t = 'General tip: after installing any new tool, [restart the editor] so the new PATH is picked up.' }
        @{ c = 'Cyan';   t = '=======================================================================' }
    )
}

function Say($level, $msg) {
    switch ($level) {
        'OK'   { Write-Host "[OK]   $msg" -ForegroundColor Green }
        'WARN' { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
        'FAIL' { Write-Host "[FAIL] $msg" -ForegroundColor Red }
        default { Write-Host "       $msg" }
    }
}

function Hint($msg) { Write-Host "       $msg" -ForegroundColor DarkGray }

if ($Guide) {
    foreach ($l in $G[$Lang]) {
        if ($l.c) { Write-Host $l.t -ForegroundColor $l.c } else { Write-Host $l.t }
    }
    exit 0
}

if (-not $Target) {
    Say FAIL ($T.NoTarget)
    Hint ($T.NoTargetHint)
    exit 1
}

Write-Host ($T.Checking) -ForegroundColor Cyan

# --- 1. Visual Studio / MSVC ---
$vsPath = ''
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path $vswhere) {
    $vsPath = (& $vswhere -latest -products * `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath) -split "`r?`n" |
        Where-Object { $_ } | Select-Object -First 1
}
if (-not $vsPath) {
    foreach ($p in @(
        'D:\Microsoft Visual Studio\Community',
        'C:\Program Files\Microsoft Visual Studio\2022\Community',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise'
    )) {
        if (Test-Path (Join-Path $p 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')) { $vsPath = $p; break }
    }
}
$clExe = $null
if ($vsPath -and (Test-Path (Join-Path $vsPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll'))) {
    Say OK ($T.VsFound -f $vsPath)
    $clExe = Get-ChildItem (Join-Path $vsPath 'VC\Tools\MSVC\*\bin\Hostx64\x64\cl.exe') -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($clExe) { Say OK ($T.ClFound -f $clExe.FullName) }
    else {
        Say WARN ($T.ClMissing)
        Hint ($T.ClMissingHint)
    }
} else {
    Say FAIL ($T.VsMissing)
    Hint ($T.VsAuto)
    Hint ($T.VsAutoCont)
    Hint ($T.VsManual)
    Hint ($T.VsManualHint)
}

# --- 2. TeX 发行版 / 引擎 ---
$engines = @{}
foreach ($e in @('xelatex', 'pdflatex', 'latexmk')) {
    $c = Get-Command $e -ErrorAction SilentlyContinue
    if ($c) { $engines[$e] = $c.Source }
}
if ($engines.Count -eq 0) {
    Say FAIL ($T.TexMissing)
    Hint ($T.TexAuto)
    Hint ($T.TexManual)
    Hint ($T.TexSkip)
} else {
    $joined = ($engines.Values -join ' ')
    $distro = if ($joined -match 'MiKTeX') { 'MiKTeX' } elseif ($joined -match 'texlive') { 'TeX Live' } else { 'Unknown' }
    Say OK ($T.TexDistro -f $distro)
    foreach ($k in $engines.Keys) { Say OK ($T.TexEngine -f $k, $engines[$k]) }
    if (-not $engines.ContainsKey('xelatex')) {
        Say WARN ($T.XelatexMissing)
        Hint ($T.XelatexHint)
    }
}

# --- 3. Python ---
$pyExe = $null
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
# 排除 Windows 自带的应用执行别名占位（WindowsApps\python.exe），它并非真正的解释器
if ($pyCmd -and $pyCmd.Source -notmatch '\\WindowsApps\\') { $pyExe = $pyCmd.Source }
if (-not $pyExe) {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        $p = & py -c "import sys;print(sys.executable)" 2>$null
        if ($p) { $pyExe = ($p -split "`r?`n" | Where-Object { $_ } | Select-Object -First 1) }
    }
}
if (-not $pyExe) {
    foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
        'D:\Program Files\Python\python.exe',
        'C:\Program Files\Python313\python.exe'
    )) { if (Test-Path $p) { $pyExe = $p; break } }
}
if ($pyExe) {
    Say OK ($T.PyFound -f $pyExe)
    $pyVer = (& $pyExe --version 2>&1) -join ''
    if ($pyVer) { Say OK ($T.PyVer -f ($pyVer -replace '^Python\s*', '')) }
} else {
    Say WARN ($T.PyMissing)
    Hint ($T.PyAuto)
    Hint ($T.PyManual)
    Hint ($T.PySkip)
}

# --- 4. 编辑器扩展 ---
$extRoots = @()
foreach ($d in @('.trae-cn', '.trae', '.vscode')) {
    $p = Join-Path $env:USERPROFILE "$d\extensions"
    if (Test-Path $p) { $extRoots += $p }
}
$need = @{
    'llvm-vs-code-extensions.vscode-clangd' = $T.D_clangd
    'vadimcn.vscode-lldb'                   = $T.D_lldb
    'james-yu.latex-workshop'               = $T.D_latex
    'ms-python.python'                      = $T.D_py
}
foreach ($id in $need.Keys) {
    $hit = $false
    foreach ($root in $extRoots) {
        if (Get-ChildItem $root -Filter "$id-*" -ErrorAction SilentlyContinue) { $hit = $true; break }
    }
    if ($hit) { Say OK ($T.ExtInstalled -f $need[$id]) }
    else {
        Say WARN ($T.ExtMissing -f $need[$id])
        $parts = $id -split '\.', 2
        Hint ($T.ExtHint1 -f $id)
        Hint ($T.ExtHint2 -f $parts[0], $parts[1])
    }
}

if ($CheckOnly) { Write-Host ($T.CheckDone) -ForegroundColor Cyan; exit 0 }

# --- 5. 写入配置 ---
$assets = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'assets'
if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }
$Target = (Resolve-Path $Target).Path
$vscode = Join-Path $Target '.vscode'
New-Item -ItemType Directory -Path $vscode -Force | Out-Null

Copy-Item (Join-Path $assets 'build.ps1') (Join-Path $Target 'build.ps1') -Force

# launch.json：按 -Lang 本地化两个调试配置名 / localize the two debug config names
$launch = Get-Content (Join-Path $assets 'launch.json') -Raw | ConvertFrom-Json
$launch.configurations[0].name = $T.L_cpp
$launch.configurations[1].name = $T.L_py
$launch | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $vscode 'launch.json') -Encoding UTF8

# tasks.json：按 -Lang 决定编译脚本的终端输出语言 / inject output language into the build task
$tasks = Get-Content (Join-Path $assets 'tasks.json') -Raw | ConvertFrom-Json
if ($Lang -ne 'zh') { $tasks.tasks[0].args += @('-Lang', $Lang) }
$tasks | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $vscode 'tasks.json') -Encoding UTF8

# settings.json：注入 clangd 的 MSVC 头文件路径（修 C/C++ 红波浪线）+ Python 解释器路径
$settings = Get-Content (Join-Path $assets 'settings.json') -Raw | ConvertFrom-Json
if ($clExe) {
    $driver = $clExe.FullName.Replace('\', '/')
    $settings | Add-Member -NotePropertyName 'clangd.arguments' -NotePropertyValue @("--query-driver=$driver") -Force
}
if ($pyExe) {
    $settings | Add-Member -NotePropertyName 'python.defaultInterpreterPath' -NotePropertyValue $pyExe -Force
}
$settings | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $vscode 'settings.json') -Encoding UTF8

Write-Host ($T.Written -f $Target) -ForegroundColor Green
Write-Host ($T.NextStep) -ForegroundColor Cyan
Write-Host ($T.Samples) -ForegroundColor Cyan