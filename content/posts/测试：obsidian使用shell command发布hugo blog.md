---
title: 测试：obsidian使用shell command发布hugo blog
date: 2025-10-16T13:58:28+08:00
draft: false
---


文科生用obsidian写md，然后特定扔到vscode里面的terminal去上传。离开了vscode开terminal就特别没有安全感。以前写脚本心里是有挑战和抗拒的，现在有了ai就好很多。ai赋能文科生。
Pasted image 20251008204019.png]]

## 发布时显示

```
===== Hugo 一键发布 =====

[13:45:22] 正在验证输入文件
当前文件: 我的文章.md

[13:45:23] 请选择发布位置
1. 博客文章 (content/posts)
2. 关于页面 (content/about)
3. 自定义目录
X. 取消操作

您的选择 [1/2/3/X]: 1

[13:45:25] 准备发布到: D:\MyHugoSite\content\posts

[13:45:25] 正在复制文件
原始位置: D:\ObsidianVault\笔记\我的文章.md
目标位置: D:\MyHugoSite\content\posts\我的文章.md
✅ 文件复制成功

[13:45:26] 执行 Git 操作
拉取远程更改...
Already up to date.
添加更改到 Git...
创建提交: 发布: 我的文章.md => posts
[main 1a2b3c4] 发布: 我的文章.md => posts
 1 file changed, 10 insertions(+)
推送到远程仓库...
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Writing objects: 100% (3/3), 745 bytes | 745.00 KiB/s, done.
✅ Git 操作成功完成
✅ Vercel 将在60秒内开始部署

发布成功！Vercel 将在60秒内自动部署。
按任意键关闭窗口 (将在 5秒后自动关闭)...

```


Shellpower.ps1 
```
param(
    [Parameter(Mandatory=$true)]
    [string]$filePath
)

# ====== 用户配置区域 ======
$HUGO_ROOT = "D:\MyHugoSite"           # Hugo 站点根目录
$HUGO_CONTENT = "$HUGO_ROOT\content"   # 内容目录
$DEFAULT_TARGET = "posts"              # 默认发布目录
$GIT_BRANCH = "main"                   # Git 分支名称
# =========================

function Write-Step($message) {
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] $message" -ForegroundColor Cyan
}

function Write-ErrorDetail($message) {
    Write-Host "❌ 错误: $message" -ForegroundColor Red
    $global:errorOccurred = $true
}

function Write-Success($message) {
    Write-Host "✅ $message" -ForegroundColor Green
}

function Show-ExitMessage($seconds = 5) {
    if ($global:errorOccurred) {
        Write-Host "`n发布失败！请检查以上错误信息。" -BackgroundColor DarkRed -ForegroundColor White
        $message = "按任意键退出 (将在 {0}秒后自动关闭)..." -f $seconds
    } else {
        Write-Host "`n发布成功！Vercel 将在60秒内自动部署。" -BackgroundColor DarkGreen -ForegroundColor White
        $message = "按任意键关闭窗口 (将在 {0}秒后自动关闭)..." -f $seconds
    }
    
    # 倒计时自动关闭
    $counter = $seconds
    while ($counter -gt 0) {
        Write-Host "`r$message" -NoNewline -ForegroundColor Yellow
        Start-Sleep 1
        $counter--
    }
}

# 初始化错误标志
$global:errorOccurred = $false

Write-Host "`n===== Hugo 一键发布 =====`n" -ForegroundColor Magenta
Write-Step "正在验证输入文件"
Write-Host "当前文件: $([System.IO.Path]::GetFileName($filePath))"

if (-not (Test-Path $filePath)) {
    Write-ErrorDetail "文件不存在: $filePath"
    Write-ErrorDetail "可能原因: 文件被移动或已删除"
    Show-ExitMessage
    exit 1
}

# 显示目录选择菜单
Write-Step "请选择发布位置"
Write-Host "1. 博客文章 (content/posts)"
Write-Host "2. 关于页面 (content/about)"
Write-Host "3. 自定义目录"
Write-Host "X. 取消操作"

$choice = Read-Host "`n您的选择 [1/2/3/X]"
$targetDir = ""

switch ($choice) {
    '1' { $targetDir = "posts" }
    '2' { $targetDir = "about" }
    '3' { 
        $targetDir = Read-Host "`n请输入目录名称 (例如: 'projects' 不要包含路径分隔符)"
        
        # 验证自定义目录名称
        if ($targetDir -match '[\\/:*?"<>|]') {
            Write-ErrorDetail "目录名称包含非法字符: $targetDir"
            Write-ErrorDetail "请使用字母、数字和下划线的组合"
        }
    }
    'X' { 
        Write-Info "操作已取消"
        Show-ExitMessage 2
        exit
    }
    default { 
        $targetDir = $DEFAULT_TARGET
        Write-Host "使用默认目录: $targetDir" -ForegroundColor Yellow
    }
}

if ([string]::IsNullOrWhiteSpace($targetDir)) {
    Write-ErrorDetail "未指定目标目录"
    Show-ExitMessage
    exit 1
}

# 构建完整目标路径
$targetPath = Join-Path $HUGO_CONTENT $targetDir

Write-Step "准备发布到: $targetPath"

# 验证目标目录
if (-not (Test-Path $HUGO_CONTENT)) {
    Write-ErrorDetail "找不到 Hugo 内容目录: $HUGO_CONTENT"
    Write-ErrorDetail "请检查脚本配置中的 `$HUGO_CONTENT` 变量"
}
elseif (-not (Test-Path $targetPath) -and $choice -ne '3') {
    Write-ErrorDetail "目标目录不存在: $targetPath"
    Write-ErrorDetail "请检查 Hugo 内容目录结构"
    
    $validDirs = Get-ChildItem $HUGO_CONTENT -Directory | Select-Object -ExpandProperty Name
    if ($validDirs) {
        Write-Host "`n可用的内容目录:" -ForegroundColor Yellow
        $validDirs -join ", "
    }
}
else {
    # 如果目录不存在但用户选择自定义，尝试创建
    if ($choice -eq '3' -and -not (Test-Path $targetPath)) {
        Write-Host "创建新目录: $targetPath" -ForegroundColor Blue
        try {
            New-Item -ItemType Directory -Path $targetPath -Force -ErrorAction Stop | Out-Null
            Write-Success "目录创建成功"
        }
        catch {
            Write-ErrorDetail "无法创建目录: $_"
            Write-ErrorDetail "检查是否有足够的权限"
        }
    }

    # 复制文件操作
    if (-not $errorOccurred) {
        $fileName = Split-Path $filePath -Leaf
        $destination = Join-Path $targetPath $fileName
        
        Write-Step "正在复制文件"
        Write-Host "原始位置: $filePath"
        Write-Host "目标位置: $destination"
        
        try {
            Copy-Item -Path $filePath -Destination $destination -Force -ErrorAction Stop
            Write-Success "文件复制成功"
        }
        catch {
            Write-ErrorDetail "文件复制失败: $_"
            Write-ErrorDetail "可能原因: 目标路径无效或被其他进程占用"
        }
    }
}

# Git 操作
if (-not $errorOccurred) {
    Write-Step "执行 Git 操作"
    
    try {
        Set-Location $HUGO_ROOT -ErrorAction Stop
        
        # 检查是否在 Git 仓库中
        $inGitRepo = git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0 -or $inGitRepo -ne "true") {
            Write-ErrorDetail "当前目录不是 Git 仓库: $HUGO_ROOT"
            Write-ErrorDetail "请使用 `git init` 初始化仓库"
            Show-ExitMessage
            exit 1
        }
        
        Write-Host "拉取远程更改..." -ForegroundColor Cyan
        git pull origin $GIT_BRANCH 2>&1 | ForEach-Object { Write-Host $_ }
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorDetail "拉取远程更改失败 (代码: $LASTEXITCODE)"
            Write-ErrorDetail "解决方法: 手动解决冲突后重试"
        }
        else {
            Write-Host "添加更改到 Git..." -ForegroundColor Cyan
            git add .
            
            $commitMsg = "发布: $fileName => $targetDir"
            Write-Host "创建提交: $commitMsg" -ForegroundColor Cyan
            git commit -m $commitMsg
            
            Write-Host "推送到远程仓库..." -ForegroundColor Cyan
            git push origin $GIT_BRANCH 2>&1 | ForEach-Object { Write-Host $_ }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Git 操作成功完成"
                Write-Success "Vercel 将在60秒内开始部署"
            }
            else {
                Write-ErrorDetail "推送失败 (代码: $LASTEXITCODE)"
                Write-ErrorDetail "常见原因:"
                Write-ErrorDetail "1. 网络连接问题"
                Write-ErrorDetail "2. Git 凭证过期（运行: git credential-manager delete https://github.com）"
                Write-ErrorDetail "3. 远程仓库权限不足"
            }
        }
    }
    catch {
        Write-ErrorDetail "Git 操作失败: $_"
        Write-ErrorDetail "详细信息: $($_.Exception)"
    }
}

# 显示退出信息
Show-ExitMessage

```

发生错误时
```
<TEXT>

❌ 错误: 推送失败 (代码: 128)

❌ 错误: 常见原因:

❌ 错误: 1. 网络连接问题

❌ 错误: 2. Git 凭证过期(运行: git credential-manager delete https://github.com)

❌ 错误: 3. 远程仓库权限不足

发布失败！请检查以上错误信息。

按任意键退出 (将在 5秒后自动关闭)...
```

1
