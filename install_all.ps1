# 一次把三個 MR 作品裝進「所有」接上電腦的 Quest 頭盔（Windows 10 / 11）
# 用法：雙擊 install_all.bat（不用自己開 PowerShell）
# - 沒有 adb：自動下載 Google 官方的 platform-tools 放在這個資料夾
# - 沒有 APK：自動從 GitHub 下載最新版
$ErrorActionPreference = 'Continue'   # adb 會把一般訊息寫到 stderr，不能用 Stop
$ProgressPreference = 'SilentlyContinue'   # 關掉進度條，下載才不會變很慢
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $PSScriptRoot

$apks = @('MR_Throw', 'MR_Whack', 'MR_Butterfly')
$url  = 'https://github.com/hitaiwan0705/MR_Throw-apps/releases/latest/download'

# 1. 找 adb
$cands = @(
  (Join-Path $PSScriptRoot 'platform-tools\adb.exe'),
  (Join-Path $env:ProgramFiles 'Meta Quest Developer Hub\resources\bin\adb.exe'),
  (Join-Path $env:ProgramFiles 'Oculus Developer Hub\resources\bin\adb.exe'),
  (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')
)
$adb = $cands | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $adb) { $c = Get-Command adb -ErrorAction SilentlyContinue; if ($c) { $adb = $c.Source } }
if (-not $adb) {
  Write-Host '下載 adb（Google platform-tools）...'
  try {
    Invoke-WebRequest 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile 'platform-tools.zip' -UseBasicParsing -ErrorAction Stop
    Expand-Archive 'platform-tools.zip' -DestinationPath $PSScriptRoot -Force -ErrorAction Stop
  } catch { Write-Host "下載 adb 失敗（需要網路）：$_" -ForegroundColor Red; exit 1 }
  Remove-Item 'platform-tools.zip'
  $adb = Join-Path $PSScriptRoot 'platform-tools\adb.exe'
}
Write-Host "adb：$adb"

# 2. 準備 APK
foreach ($a in $apks) {
  if (-not (Test-Path "$a.apk")) {
    Write-Host "下載 $a.apk（約 85 MB）..."
    try { Invoke-WebRequest "$url/$a.apk" -OutFile "$a.apk" -UseBasicParsing -ErrorAction Stop }
    catch { Write-Host "下載 $a.apk 失敗：$_  （可以先到 GitHub Releases 手動下載，放在這個資料夾）" -ForegroundColor Red; exit 1 }
  }
}

# 3. 找頭盔
& $adb start-server 2>&1 | Out-Null
$lines  = @(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' })
$devs   = @($lines | Where-Object { $_ -match '\tdevice$' }       | ForEach-Object { ($_ -split '\t')[0] })
$unauth = @($lines | Where-Object { $_ -match '\tunauthorized$' } | ForEach-Object { ($_ -split '\t')[0] })
if ($unauth.Count -gt 0) { Write-Host "注意：這些頭盔還沒按「允許 USB 偵錯」：$($unauth -join ', ')" -ForegroundColor Yellow }
if ($devs.Count -eq 0) {
  Write-Host '沒有找到可以安裝的頭盔。請檢查：' -ForegroundColor Red
  Write-Host '  1. 線要能傳資料（只能充電的線不行）'
  Write-Host '  2. 頭盔開了開發者模式，而且開完有重新開機'
  Write-Host '  3. 頭盔 設定 > 開發者 > 關閉「Link 自動連線」，拔線重插'
  Write-Host '  4. 戴上頭盔按「允許 USB 偵錯」（勾「一律允許」）'
  Write-Host '  5. 還是不行：安裝 Meta 的「Oculus ADB Drivers」（需要系統管理員）'
  exit 1
}
Write-Host "找到 $($devs.Count) 台頭盔：$($devs -join ', ')，同時安裝中（每台約 1-2 分鐘）..."

# 4. 每台頭盔同時安裝
$jobs = foreach ($d in $devs) {
  Start-Job -ArgumentList $adb, $d, $apks, $PSScriptRoot -ScriptBlock {
    param($adb, $d, $apks, $dir)
    Set-Location $dir
    $ok = 0; $msg = @()
    foreach ($a in $apks) {
      $out = (& $adb -s $d install -r -g "$a.apk" 2>&1 | Out-String)
      if ($out -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE') {
        # 頭盔上是舊簽章的版本：移除後重裝
        $pkg = 'com.xrcourse.' + $a.ToLower().Replace('_', '')
        & $adb -s $d uninstall $pkg 2>&1 | Out-Null
        $out = (& $adb -s $d install -r -g "$a.apk" 2>&1 | Out-String)
      }
      if ($out -match 'Success') { $ok++; $msg += "$a OK" }
      else { $msg += "$a 失敗 " + (($out -split "`n" | Where-Object { $_ -match 'Failure|error' } | Select-Object -First 1)) }
    }
    "[$d] $ok/3  " + ($msg -join ' | ')
  }
}
$jobs | Wait-Job | Receive-Job | ForEach-Object { if ($_ -match '\] 3/3') { Write-Host $_ -ForegroundColor Green } else { Write-Host $_ -ForegroundColor Red } }
$jobs | Remove-Job
Write-Host ''
Write-Host '完成。頭盔裡：應用程式庫 > 右上篩選改成「未知來源」就看得到三個作品。'
