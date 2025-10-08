param([string]$filePath)

# 设置严格错误处理
$ErrorActionPreference = 'Stop'

# 配置
$HUGO_ROOT = "C:\Users\yolo\Desktop\docs\yolonotes"

# 辅助函数
function Write-Status($message) {
    Write-Host "==> $message" -ForegroundColor Cyan
}

function Write-Error($message) {
    Write-Host "ERROR: $message" -ForegroundColor Red
    exit 1
}

function Write-Success($message) {
    Write-Host "SUCCESS: $message" -ForegroundColor Green
}

# 主逻辑
try {
    # 验证文件
    if (-not (Test-Path $filePath)) {
        Write-Error "File not found: $filePath"
    }
    
    # 检查文件类型
    if (-not ($filePath -match "\.md$")) {
        Write-Error "Only markdown files are supported"
    }
    
    # 切换到Hugo目录
    Write-Status "Switching to Hugo directory..."
    Set-Location $HUGO_ROOT
    
    # 复制文件
    Write-Status "Copying file to posts directory..."
    Copy-Item $filePath "content\posts\" -Force
    
    # Git操作
    Write-Status "Committing changes..."
    git add .
    git commit -m "Publish: $([System.IO.Path]::GetFileName($filePath))"
    
    Write-Status "Pushing to remote..."
    git push origin main
    
    Write-Success "File published successfully!"
    Write-Host "Vercel will deploy the changes shortly." -ForegroundColor Yellow
}
catch {
    Write-Error $_.Exception.Message
}
