# XR 課程 Quest 3 MR 作品下載

三個 Meta Quest 3 混合實境（MR）作品：**投擲**、**打地鼠**、**蝴蝶**。

## 下載

到 **[Releases（最新版本）](../../releases/latest)**，下載這三個檔案：

| 作品 | 檔案 |
|---|---|
| 投擲：隔空把方塊吸到手上，丟向在地板上亂開的小坦克（60 秒） | `MR_Throw.apk` |
| 打地鼠：地鼠從房間裡的家具和地板冒出來，走過去打（30 秒） | `MR_Whack.apk` |
| 蝴蝶：伸手不動 3 秒，蝴蝶會停在手上 | `MR_Butterfly.apk` |

## 安裝步驟（摘要）

1. **頭盔開啟開發者模式**（每台一次）：手機 Meta Horizon App → 裝置 → 頭戴裝置設定 → 開發者模式 → 開啟，然後**頭盔重新開機**
2. **關閉 Link 自動連線**：頭盔 設定 → 開發者 → 關閉「Link 自動連線」
3. **掃描教室**：頭盔 設定 → 實體空間 → 空間設定
4. **安裝**：用能傳資料的 USB-C 線接電腦，頭盔裡按「允許 USB 偵錯」，打開 Meta Quest Developer Hub，把 3 個 APK 拖進 Device Manager 的 Apps 區塊
   - 或用指令：`adb install -r -g MR_Throw.apk`（另外兩個同理）
5. **開始玩**：頭盔 應用程式庫 → 篩選改成「未知來源」

## 一次裝很多台（Windows 10 / 11，學校電腦）

1. 這個頁面右上綠色「**Code → Download ZIP**」，下載後**解壓縮**（在 ZIP 上按右鍵 →「解壓縮全部」，不要直接在 ZIP 裡面執行）
2. 頭盔：開發者模式已開、已重新開機、設定 → 開發者 → 關閉「Link 自動連線」
3. 用能傳資料的 USB-C 線把頭盔接上電腦（電腦有幾個 USB 孔就能同時接幾台）
4. 戴上每一台頭盔，按「**允許 USB 偵錯**」並勾「一律允許這台電腦」
5. 雙擊解壓縮資料夾裡的 **`install_all.bat`**
   - 第一次會自動下載 adb 工具和 3 個 APK（約 260 MB，需要網路）
   - 跳出「Windows 已保護您的電腦」：按「其他資訊」→「仍要執行」
6. 等它顯示每台頭盔 `3/3`（綠色）就完成；換下一批頭盔，再雙擊一次

**電腦一直說找不到頭盔**：先戴上頭盔看有沒有「允許 USB 偵錯」；還是不行，安裝 Meta 的 [Oculus ADB Drivers](https://developers.meta.com/horizon/downloads/package/oculus-adb-drivers/)（要系統管理員權限），或改用 Meta Quest Developer Hub 拖拉安裝。

## 一次裝很多台（Mac）

1. 下載這個專案：右上「Code → Download ZIP」，解壓縮
2. 把頭盔接上電腦（USB 集線器可同時接多台），每台都按「允許 USB 偵錯」
3. 打開「終端機」，把解壓縮後的資料夾拖進去，執行：

```bash
./install_all.sh
```

腳本會自動下載最新的 3 個 APK，**同時**裝進所有接上的頭盔，最後列出每台結果。
要用 Wi-Fi：每台先接線執行一次 `adb tcpip 5555`，再 `./install_all.sh wifi <頭盔1的IP> <頭盔2的IP> …`

## 常見問題

| 狀況 | 解法 |
|---|---|
| 電腦看不到頭盔 | 線只能充電、開發者模式沒生效（要重開機）、或頭盔在 Link 模式 |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | 先從頭盔移除舊的同名作品再裝 |
| 沒有讀到房間（沒有牆面網格） | 這間教室還沒做空間設定 |
