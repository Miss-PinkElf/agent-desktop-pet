$ErrorActionPreference = "Stop"
$VenvPath = Join-Path $PSScriptRoot ".venv"
$RequirementsPath = Join-Path $PSScriptRoot "requirements.txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend 环境初始化脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path $VenvPath) {
    Write-Host "[INFO] 虚拟环境已存在: $VenvPath" -ForegroundColor Yellow
} else {
    Write-Host "[STEP 1] 创建虚拟环境..." -ForegroundColor Green
    python -m venv $VenvPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] 创建虚拟环境失败，请确保已安装 Python" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] 虚拟环境创建成功" -ForegroundColor Green
}

$ActivateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
if (-not (Test-Path $ActivateScript)) {
    Write-Host "[ERROR] 激活脚本不存在" -ForegroundColor Red
    exit 1
}

Write-Host "[STEP 2] 激活虚拟环境并安装依赖..." -ForegroundColor Green
& $ActivateScript

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
Write-Host "后续使用请运行:" -ForegroundColor White
Write-Host "  .\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host ""
