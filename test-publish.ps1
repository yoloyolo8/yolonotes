param([string]$filePath)
$ErrorActionPreference = 'Stop'
$HUGO_ROOT = "C:\Users\yolo\Desktop\docs\yolonotes"
cd $HUGO_ROOT
Write-Host "Copying $filePath to posts..."
Copy-Item $filePath "content\posts\" -Force
git add .
git commit -m "Publish new post"
git push origin main
Write-Host "Done!"
