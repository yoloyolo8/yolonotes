param([string]$filePath)

# 设置严格错误处理
$ErrorActionPreference = 'Stop'

# 配置
$HUGO_ROOT = "C:\Users\yolo\Desktop\docs\yolonotes"

# 添加Windows通知功能
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Notification {
    param (
        [string]$title,
        [string]$message,
        [ValidateSet('Info', 'Error', 'Success')]
        [string]$type = 'Info'
    )
    
    $notification = New-Object System.Windows.Forms.NotifyIcon
    $notification.Icon = [System.Drawing.SystemIcons]::Information
    $notification.BalloonTipTitle = $title
    $notification.BalloonTipText = $message
    $notification.Visible = $true
    
    switch ($type) {
        'Error' { $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Error }
        'Success' { $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info }
        default { $notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info }
    }
    
    $notification.ShowBalloonTip(5000)
    Start-Sleep -Seconds 1
    $notification.Dispose()
}

# 辅助函数
function Write-Status($message) {
    Write-Host "==> $message" -ForegroundColor Cyan
}

function Write-Error($message) {
    Write-Host "ERROR: $message" -ForegroundColor Red
    Show-Notification "发布失败" $message "Error"
    exit 1
}

function Write-Success($message) {
    Write-Host "SUCCESS: $message" -ForegroundColor Green
}

# 主逻辑
try {
    # 验证文件
    if (-not (Test-Path $filePath)) {
        Write-Error "文件未找到: $filePath"
    }
    
    # 检查文件类型
    if (-not ($filePath -match "\.md$")) {
        Write-Error "仅支持 Markdown 文件"
    }
    
    # 切换到Hugo目录
    Write-Status "切换到 Hugo 目录..."
    Set-Location $HUGO_ROOT
    
    # 复制文件
    Write-Status "复制文件到 posts 目录..."
    Copy-Item $filePath "content\posts\" -Force
    
    # Git操作
    Write-Status "提交更改..."
    git add .
    git commit -m "发布: $([System.IO.Path]::GetFileName($filePath))"
    
    Write-Status "推送到远程仓库..."
    git push origin main
    
    Write-Success "文章发布成功！"
    Show-Notification "发布成功" "文章已成功发布到博客，Vercel 将在稍后完成部署。" "Success"
}
catch {
    Write-Error $_.Exception.Message
}
