# 编译 C/C++ 源文件（MSVC）。tasks.json 自动调用，也可手动运行。
# 单文件：-Source xx.cpp ；多文件：-Source xx.cpp -All（编译同目录全部 .c/.cpp/.cc/.cxx）
# VS 路径自动探测，无需硬编码；如有多套 VS 可用 -VsPath 指定。
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [switch]$All,
    [string]$VsPath = ''
)

$ErrorActionPreference = 'Stop'

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
if (-not $VsPath) { throw "未找到 Visual Studio，请安装 VS2022（勾选 [使用 C++ 的桌面开发] 工作负载）" }

$devShell = Join-Path $VsPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
if (-not (Test-Path $devShell)) { throw "无效的 VS 路径: $VsPath" }

# 进入 VS 开发环境，使 cl.exe 及其头文件/库路径可用
Import-Module $devShell
Enter-VsDevShell -VsInstallPath $VsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64' | Out-Null

$source = (Resolve-Path $Source).Path
$outExe = [System.IO.Path]::ChangeExtension($source, '.exe')
$workDir = Split-Path $source

# 单文件默认；-All 时编译同目录内全部 C/C++ 源文件再统一链接
if ($All) {
    $compileList = Get-ChildItem -LiteralPath $workDir -File |
        Where-Object { $_.Extension -in @('.c', '.cpp', '.cc', '.cxx') } |
        Sort-Object Name | ForEach-Object { $_.FullName }
    if ($compileList.Count -eq 0) { throw "目录内未找到 .c/.cpp/.cc/.cxx 源文件: $workDir" }
    Write-Host "多文件编译（$($compileList.Count) 个源文件）" -ForegroundColor Cyan
} else {
    $compileList = @($source)
}

Push-Location $workDir
try {
    cl /nologo /EHsc /Zi $compileList "/Fe:$outExe"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "编译失败，退出码 $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

Write-Host "编译成功: $outExe" -ForegroundColor Green