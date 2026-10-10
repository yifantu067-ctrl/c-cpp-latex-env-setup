# 编译 C/C++ 源文件（MSVC）。tasks.json 自动调用，也可手动运行。
# Build C/C++ sources with MSVC. Called by tasks.json, or run manually.
# 单文件：-Source xx.cpp ；多文件：-Source xx.cpp -All（编译同目录全部 .c/.cpp/.cc/.cxx）
# Single file: -Source xx.cpp ; multiple files: -Source xx.cpp -All
# 所有编译产物（.obj/.pdb/.ilk/.exe）统一放进项目下的 build\ 目录，项目根保持干净。
# All build outputs (.obj/.pdb/.ilk/.exe) go into a build\ folder so the project root stays clean.
# VS 路径自动探测，无需硬编码；如有多套 VS 可用 -VsPath 指定。
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [switch]$All,
    [string]$VsPath = '',
    [ValidateSet('zh', 'en')][string]$Lang = 'zh'
)

$ErrorActionPreference = 'Stop'

$S = @{
    zh = @{
        NoVs         = '未找到 Visual Studio，请安装 VS2022（勾选 [使用 C++ 的桌面开发] 工作负载）'
        BadVs        = '无效的 VS 路径: {0}'
        NoSources    = '目录内未找到 .c/.cpp/.cc/.cxx 源文件: {0}'
        MultiBuild   = '多文件编译（{0} 个源文件）'
        BuildFailed  = '编译失败，退出码 {0}'
        BuildOk      = '编译成功: {0}'
    }
    en = @{
        NoVs         = 'Visual Studio not found. Install VS2022 with the [Desktop development with C++] workload.'
        BadVs        = 'Invalid VS path: {0}'
        NoSources    = 'No .c/.cpp/.cc/.cxx source files found in: {0}'
        MultiBuild   = 'Multi-file build ({0} source files)'
        BuildFailed  = 'Build failed, exit code {0}'
        BuildOk      = 'Build succeeded: {0}'
    }
}
$T = $S[$Lang]

# 1) 用 vswhere 自动定位装有 C++ 工具的最新 Visual Studio
if (-not $VsPath) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
        $VsPath = (& $vswhere -latest -products * `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath) -split "`r?`n" |
            Where-Object { $_ } | Select-Object -First 1
    }
}
# 2) vswhere 不可用时回退到常见安装路径
if (-not $VsPath) {
    foreach ($p in @(
        'D:\Microsoft Visual Studio\Community',
        'C:\Program Files\Microsoft Visual Studio\2022\Community',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise'
    )) {
        if (Test-Path (Join-Path $p 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')) { $VsPath = $p; break }
    }
}
if (-not $VsPath) { throw ($T.NoVs) }

$devShell = Join-Path $VsPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
if (-not (Test-Path $devShell)) { throw ($T.BadVs -f $VsPath) }

# 进入 VS 开发环境，使 cl.exe 及其头文件/库路径可用
Import-Module $devShell
Enter-VsDevShell -VsInstallPath $VsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64' | Out-Null

$source = (Resolve-Path $Source).Path
$workDir = Split-Path $source

# 单文件默认；-All 时编译同目录内全部 C/C++ 源文件再统一链接
if ($All) {
    $compileList = Get-ChildItem -LiteralPath $workDir -File |
        Where-Object { $_.Extension -in @('.c', '.cpp', '.cc', '.cxx') } |
        Sort-Object Name | ForEach-Object { $_.FullName }
    if ($compileList.Count -eq 0) { throw ($T.NoSources -f $workDir) }
    Write-Host ($T.MultiBuild -f $compileList.Count) -ForegroundColor Cyan
} else {
    $compileList = @($source)
}

# 编译产物统一输出到 build\，项目根目录不残留 .obj/.pdb/.ilk/.exe
$buildDir = Join-Path $workDir 'build'
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir -Force | Out-Null }
$outExe = Join-Path $buildDir ([System.IO.Path]::GetFileNameWithoutExtension($source) + '.exe')

# 在 build\ 下执行 cl：.obj / .pdb / .ilk 默认都落在当前目录，即 build\
Push-Location $buildDir
try {
    cl /nologo /EHsc /Zi $compileList "/Fe:$outExe"
    if ($LASTEXITCODE -ne 0) {
        Write-Host ($T.BuildFailed -f $LASTEXITCODE) -ForegroundColor Red
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

Write-Host ($T.BuildOk -f $outExe) -ForegroundColor Green