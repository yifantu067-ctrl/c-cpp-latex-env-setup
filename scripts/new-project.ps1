# 探测本机 C/C++/LaTeX 环境并把一键编译调试配置写入目标项目目录
# 零基础用户：先跑 -Guide 看逐步安装指引，装完再带 -Target 跑一次
param(
    [string]$Target,
    [switch]$CheckOnly,   # 只做环境自检，不写文件
    [switch]$Guide        # 打印零基础逐步安装指引后退出（无需 -Target）
)

$ErrorActionPreference = 'Stop'

function Say($level, $msg) {
    switch ($level) {
        'OK'   { Write-Host "[OK]   $msg" -ForegroundColor Green }
        'WARN' { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
        'FAIL' { Write-Host "[FAIL] $msg" -ForegroundColor Red }
        default { Write-Host "       $msg" }
    }
}

function Hint($msg) { Write-Host "       $msg" -ForegroundColor DarkGray }

function Show-Guide {
    Write-Host ""
    Write-Host "========== 零基础逐步安装指引（从零到能跑）==========" -ForegroundColor Cyan
    Write-Host "全部安装只需做一次，之后新建项目直接复用。"
    Write-Host ""
    Write-Host "步骤 1  安装 Visual Studio 2022（提供 C/C++ 编译器 cl.exe）" -ForegroundColor Yellow
    Write-Host "  自动: winget install Microsoft.VisualStudio.2022.Community --override "
    Hint '        "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"'
    Write-Host "  手动: 下载 https://visualstudio.microsoft.com/vs/community/"
    Hint "        安装时务必勾选工作负载 [使用 C++ 的桌面开发]"
    Write-Host "  验证: 开始菜单打开 Developer PowerShell for VS 2022，输入 cl 能看到版本"
    Hint "        普通 PowerShell 里找不到 cl 属正常，脚本会自动进 VS 环境"
    Write-Host ""
    Write-Host "步骤 2  安装 MiKTeX（提供 LaTeX 引擎 xelatex）" -ForegroundColor Yellow
    Write-Host "  自动: winget install MiKTeX.MiKTeX"
    Write-Host "  手动: 下载 https://miktex.org/download （Install for me only 即可）"
    Write-Host "  验证: 重开终端执行 xelatex --version"
    Hint "        不需要 LaTeX 可跳过此步，只用 C/C++"
    Write-Host ""
    Write-Host "步骤 3  安装编辑器扩展（在扩展市场搜索安装）" -ForegroundColor Yellow
    Write-Host "  clangd          ID: llvm-vs-code-extensions.vscode-clangd   （C/C++ 补全报错）"
    Write-Host "  CodeLLDB        ID: vadimcn.vscode-lldb                     （F5 调试）"
    Write-Host "  LaTeX Workshop  ID: james-yu.latex-workshop                 （LaTeX 编译预览）"
    Hint "        或命令行: code --install-extension <上面的ID>"
    Hint "        国内版: 直接在 Trae 内置市场搜装即可（走国内镜像，无需翻墙）"
    Hint "        仍装不上: 从 Open VSX 下载 .vsix 后用 Install from VSIX... 离线安装"
    Write-Host ""
    Write-Host "步骤 4  写入项目配置" -ForegroundColor Yellow
    Write-Host "  去掉 -Guide，带 -Target 再运行本脚本一次："
    Hint '        ... -File "<skill目录>\scripts\new-project.ps1" -Target "<项目目录>"'
    Write-Host ""
    Write-Host "步骤 5  验证" -ForegroundColor Yellow
    Write-Host "  复制 assets\samples\hello.c 到项目根，打开按 F5 -> 输出 Hello World!"
    Write-Host "  复制 assets\samples\sample.tex 过去，按 Ctrl+Alt+B -> 生成 PDF"
    Write-Host ""
    Hint "通用提示: 装完任何新工具后请[重启编辑器]，否则可能读不到新的 PATH。"
    Write-Host "===================================================" -ForegroundColor Cyan
}

if ($Guide) { Show-Guide; exit 0 }

if (-not $Target) {
    Say FAIL "缺少 -Target 参数（要写入配置的项目目录）"
    Hint "想看零基础安装指引，请加 -Guide（无需 -Target）"
    exit 1
}

Write-Host "==== 环境自检 ====" -ForegroundColor Cyan

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
    Say OK "Visual Studio: $vsPath"
    $clExe = Get-ChildItem (Join-Path $vsPath 'VC\Tools\MSVC\*\bin\Hostx64\x64\cl.exe') -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($clExe) { Say OK "MSVC cl.exe: $($clExe.FullName)" }
    else {
        Say WARN "找到 VS 但缺少 MSVC 编译器"
        Hint "请打开 Visual Studio Installer -> 修改 -> 勾选 [使用 C++ 的桌面开发]"
    }
} else {
    Say FAIL "未找到 Visual Studio（C/C++ 无法编译）"
    Hint "自动安装: winget install Microsoft.VisualStudio.2022.Community --override "
    Hint '          "--quiet --wait --add Microsoft.VisualStudio.Workload.NativeDesktop"'
    Hint "手动安装: https://visualstudio.microsoft.com/vs/community/"
    Hint "安装时务必勾选工作负载 [使用 C++ 的桌面开发]"
}

# --- 2. TeX 发行版 / 引擎 ---
$engines = @{}
foreach ($e in @('xelatex','pdflatex','latexmk')) {
    $c = Get-Command $e -ErrorAction SilentlyContinue
    if ($c) { $engines[$e] = $c.Source }
}
if ($engines.Count -eq 0) {
    Say FAIL "未找到 LaTeX 引擎（LaTeX 无法编译）"
    Hint "自动安装: winget install MiKTeX.MiKTeX"
    Hint "手动安装: https://miktex.org/download"
    Hint "仅用 C/C++ 可忽略此项"
} else {
    $joined = ($engines.Values -join ' ')
    $distro = if ($joined -match 'MiKTeX') { 'MiKTeX' } elseif ($joined -match 'texlive') { 'TeX Live' } else { '未知' }
    Say OK "TeX 发行版: $distro"
    foreach ($k in $engines.Keys) { Say OK "引擎 $k : $($engines[$k])" }
    if (-not $engines.ContainsKey('xelatex')) {
        Say WARN "未找到 xelatex（中文推荐）"
        Hint "可把 settings.json 的 recipe 改为 pdflatex，或安装含 xelatex 的发行版"
    }
}

# --- 3. 编辑器扩展 ---
$extRoots = @()
foreach ($d in @('.trae-cn', '.trae', '.vscode')) {
    $p = Join-Path $env:USERPROFILE "$d\extensions"
    if (Test-Path $p) { $extRoots += $p }
}
$need = @{
    'llvm-vs-code-extensions.vscode-clangd' = 'clangd（C/C++ 补全/报错）'
    'vadimcn.vscode-lldb'                   = 'CodeLLDB（F5 调试）'
    'james-yu.latex-workshop'               = 'LaTeX Workshop（编译/预览）'
}
foreach ($id in $need.Keys) {
    $hit = $false
    foreach ($root in $extRoots) {
        if (Get-ChildItem $root -Filter "$id-*" -ErrorAction SilentlyContinue) { $hit = $true; break }
    }
    if ($hit) { Say OK "扩展已装: $($need[$id])" }
    else {
        Say WARN "缺少扩展: $($need[$id])"
        $parts = $id -split '\.', 2
        Hint "Trae 内置市场搜装即可（国内镜像，无需翻墙），或: code --install-extension $id"
        Hint "若装不上: https://open-vsx.org/extension/$($parts[0])/$($parts[1]) 下载 .vsix 后 Install from VSIX..."
    }
}

if ($CheckOnly) { Write-Host "==== 自检结束（未写入文件）====" -ForegroundColor Cyan; exit 0 }

# --- 4. 写入配置 ---
$assets = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'assets'
if (-not (Test-Path $Target)) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }
$Target = (Resolve-Path $Target).Path
$vscode = Join-Path $Target '.vscode'
New-Item -ItemType Directory -Path $vscode -Force | Out-Null

Copy-Item (Join-Path $assets 'build.ps1')   (Join-Path $Target  'build.ps1')  -Force
Copy-Item (Join-Path $assets 'tasks.json')  (Join-Path $vscode 'tasks.json')  -Force
Copy-Item (Join-Path $assets 'launch.json') (Join-Path $vscode 'launch.json') -Force

# settings.json：注入 clangd 的 MSVC 头文件路径（修 C/C++ 红波浪线）
$settings = Get-Content (Join-Path $assets 'settings.json') -Raw | ConvertFrom-Json
if ($clExe) {
    $driver = $clExe.FullName.Replace('\', '/')
    $settings | Add-Member -NotePropertyName 'clangd.arguments' -NotePropertyValue @("--query-driver=$driver") -Force
}
$settings | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $vscode 'settings.json') -Encoding UTF8

Write-Host "已写入配置: $Target" -ForegroundColor Green
Write-Host "下一步: 放入 .c/.cpp 按 F5（多文件加 -All），或放入 .tex 按 Ctrl+Alt+B" -ForegroundColor Cyan
Write-Host "示例可复制 assets\samples\ 下的 hello.c / hello.cpp / sample.tex" -ForegroundColor Cyan