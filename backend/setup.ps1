$ErrorActionPreference = "Stop"
$VenvPath = Join-Path $PSScriptRoot ".venv"
$RequirementsPath = Join-Path $PSScriptRoot "requirements.txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend 环境初始化脚本 (Python 3.11)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path $VenvPath) {
    Write-Host "[INFO] 虚拟环境已存在: $VenvPath" -ForegroundColor Yellow
} else {
    Write-Host "[STEP 1] 检查 Python 3.11..." -ForegroundColor Green
    
    $pythonCmd = $null
    try {
        $py311 = py -3.11 --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $pythonCmd = "py -3.11"
            Write-Host "[OK] 找到 Python 3.11: $py311" -ForegroundColor Green
        }
    } catch {}

    if (-not $pythonCmd) {
        try {
            $pythonVer = python --version 2>&1
            if ($pythonVer -match "3\.11") {
                $pythonCmd = "python"
                Write-Host "[OK] 使用 Python: $pythonVer" -ForegroundColor Green
            }
        } catch {}
    }

    if (-not $pythonCmd) {
        Write-Host "[ERROR] 未找到 Python 3.11，请先安装" -ForegroundColor Red
        Write-Host "下载地址: https://www.python.org/downloads/" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "[STEP 2] 创建虚拟环境..." -ForegroundColor Green
    Invoke-Expression "$pythonCmd -m venv `"$VenvPath`""
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] 创建虚拟环境失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] 虚拟环境创建成功" -ForegroundColor Green
}

$ScriptsPath = Join-Path $VenvPath "Scripts"
$ActivatePs1 = Join-Path $ScriptsPath "Activate.ps1"
$ActivateBat = Join-Path $ScriptsPath "activate.bat"
$ActivateSh = Join-Path $ScriptsPath "activate"

Write-Host "[STEP 3] 检查激活脚本..." -ForegroundColor Green
$missingScripts = @()
if (-not (Test-Path $ActivatePs1)) { $missingScripts += "Activate.ps1" }
if (-not (Test-Path $ActivateBat)) { $missingScripts += "activate.bat" }
if (-not (Test-Path $ActivateSh)) { $missingScripts += "activate" }

if ($missingScripts.Count -gt 0) {
    Write-Host "[WARN] 缺少脚本: $($missingScripts -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "[OK] 所有激活脚本已就绪" -ForegroundColor Green
    Write-Host "  - Activate.ps1 (PowerShell)" -ForegroundColor Gray
    Write-Host "  - activate.bat   (CMD)" -ForegroundColor Gray
    Write-Host "  - activate       (Bash/Git Bash)" -ForegroundColor Gray
}

Write-Host "[STEP 4] 安装依赖..." -ForegroundColor Green
& $ActivatePs1

if (Test-Path $RequirementsPath) {
    pip install -r $RequirementsPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] 部分依赖安装失败，请检查 requirements.txt" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] 依赖安装完成" -ForegroundColor Green
    }
} else {
    Write-Host "[WARN] requirements.txt 不存在，跳过依赖安装" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  初始化完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "VSCode 终端会自动激活虚拟环境" -ForegroundColor White
Write-Host "手动激活命令:" -ForegroundColor White
Write-Host "  PowerShell: .\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host "  CMD:        .\.venv\Scripts\activate.bat" -ForegroundColor Yellow
Write-Host ""
