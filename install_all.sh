#!/bin/zsh
# 一次把三個 MR 作品裝進「所有」已連上的 Quest 頭盔（USB 或 Wi-Fi 都算），各台同時進行
# 用法：
#   ./install_all.sh                 安裝到目前連上的所有頭盔
#   ./install_all.sh wifi 192.168.1.50 192.168.1.51 ...   先用 Wi-Fi 連上這些頭盔再安裝
# APK 放在跟這個腳本同一個資料夾；沒有的話會自動從 GitHub 下載最新版
set -u
cd "$(dirname "$0")"
ADB="${ADB:-/Applications/Meta VR Developer Hub.app/Contents/Resources/bin/adb}"
[[ -x "$ADB" ]] || ADB="$(command -v adb)"
[[ -n "$ADB" ]] || { echo "找不到 adb：請先安裝 Meta Quest Developer Hub"; exit 1; }
APKS=(MR_Throw MR_Whack MR_Butterfly)
URL="https://github.com/hitaiwan0705/MR_Throw-apps/releases/latest/download"

for a in $APKS; do
  if [[ ! -f $a.apk ]]; then echo "下載 $a.apk ..."; curl -fL --progress-bar -o $a.apk "$URL/$a.apk" || { echo "下載失敗：$a.apk"; exit 1; }; fi
done

if [[ "${1:-}" == wifi ]]; then
  shift
  for ip in "$@"; do "$ADB" connect "$ip:5555" | sed "s/^/  /"; done
fi

DEVICES=(${(f)"$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')"})
UNAUTH=(${(f)"$("$ADB" devices | awk 'NR>1 && $2=="unauthorized" {print $1}')"})
(( ${#UNAUTH} )) && echo "⚠ 這些頭盔還沒按「允許 USB 偵錯」：$UNAUTH"
(( ${#DEVICES} )) || { echo "沒有連上的頭盔。檢查：能傳資料的線、開發者模式（開了要重開機）、關閉 Link 自動連線"; exit 1; }
echo "找到 ${#DEVICES} 台頭盔：$DEVICES"
mkdir -p .logs

install_one() {
  local d=$1 log=".logs/${1//[:.]/_}.txt" ok=0
  : > $log
  for a in $APKS; do
    out=$("$ADB" -s $d install -r -g $a.apk 2>&1)
    if echo "$out" | grep -q INSTALL_FAILED_UPDATE_INCOMPATIBLE; then   # 舊簽章 → 移除再裝
      pkg=com.xrcourse.${(L)a//_/}   # MR_Throw → com.xrcourse.mrthrow
      "$ADB" -s $d uninstall $pkg >/dev/null 2>&1
      out=$("$ADB" -s $d install -r -g $a.apk 2>&1)
    fi
    if echo "$out" | grep -q Success; then echo "$a ✓" >> $log; ok=$((ok+1)); else echo "$a ✗ $(echo "$out" | grep -oE 'Failure.*|error.*' | head -1)" >> $log; fi
  done
  echo "[$d] $ok/3 $(tr '\n' ' ' < $log)"
}

for d in $DEVICES; do install_one $d & done
wait
echo "完成。頭盔裡：應用程式庫 → 篩選改「未知來源」"
