<p align="center">
  <img src="assets/logo.png" alt="TAT CCU" width="128">
</p>

<h1 align="center">TAT CCU</h1>

<p align="center">
  <strong>中正大學的課表、eCourse2 與校務系統，都在一個 App 裡。</strong><br>
  打開就知道下一堂在哪、還有什麼要交、誰回了你的信。
</p>

<p align="center">
  <a href="https://github.com/KoukeNeko/TAT-CCU/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/KoukeNeko/TAT-CCU?style=for-the-badge&logo=github&label=RELEASE&color=6750A4"></a>
  <a href="https://github.com/KoukeNeko/TAT-CCU/releases"><img alt="GitHub downloads" src="https://img.shields.io/github/downloads/KoukeNeko/TAT-CCU/total?style=for-the-badge&logo=github&label=DOWNLOADS&color=1F4A30"></a>
  <img alt="iOS 17+" src="https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white">
  <img alt="macOS 12+" src="https://img.shields.io/badge/macOS-12%2B-000000?style=for-the-badge&logo=apple&logoColor=white">
  <img alt="Android" src="https://img.shields.io/badge/ANDROID-3DDC84?style=for-the-badge&logo=android&logoColor=white">
  <a href="https://github.com/KoukeNeko/TAT-CCU/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/KoukeNeko/TAT-CCU?style=for-the-badge&logo=github&label=STARS&color=6750A4"></a>
</p>

<p align="center">
  <a href="#下載與安裝">下載與安裝</a>
  · <a href="#功能">功能</a>
  · <a href="PRIVACY.md">隱私權政策</a>
</p>

TAT CCU 把中正大學分散在 eCourse2、單一入口和各校務系統裡的資訊收進同一個 App：今天的課、
這週要交的作業、未讀的公告與信件，都在打開的第一個畫面。以單一入口登入一次，eCourse2 和校務系統
都能用。

**這是學生自行開發的非官方 App，與國立中正大學沒有隸屬關係。** 開發者沒有伺服器，所有資料只在你的
裝置和學校的系統之間傳遞。

## 畫面

<p align="center">
  <img src="store/app-store/iphone-6.3/01-today.jpg" width="19%" alt="今天" />
  <img src="store/app-store/iphone-6.3/02-timetable.jpg" width="19%" alt="課表" />
  <img src="store/app-store/iphone-6.3/03-course.jpg" width="19%" alt="課程" />
  <img src="store/app-store/iphone-6.3/05-calendar.jpg" width="19%" alt="行事曆" />
  <img src="store/app-store/iphone-6.3/06-messages.jpg" width="19%" alt="訊息" />
</p>

<p align="center">
  <img src="store/app-store/mac/02-timetable.jpg" width="96%" alt="macOS 上的課表" />
</p>

## 功能

### 今天

下一堂課在哪、還有幾分鐘、之後還有哪堂課，加上這週到期的作業與小考、還沒讀的公告和信件，都在
同一頁。

### 課表

一週的課一眼看完。點一堂課就看到它的最近截止、最新公告和目前成績，不必先找到
那門課的 eCourse2 頁面。

### eCourse2 課程

章節、教材、作業、討論區、成績與缺曠課都在 App 裡打開。支援作業進度（開放、繳交、截止、評分）；
討論區可以直接留言。

### 訊息

eCourse2 的信件、公告與討論集中在一處，可以讀信、回覆和寫新信。

### 行事曆

學校行事曆和你的截止日放在同一張月曆上：期中考週、放假、加退選，還有每一份作業和小考。

### 校務系統

成績查詢、圖書館館藏與借閱、請假、付款與所得、自學空間 QR Code 與空位、在學證明書、活動報名，
以及公車動態與倒數，都能在 App 裡使用，不必另外開瀏覽器登入。

### 小工具與提醒

桌面小工具顯示下一堂課和到期項目。上課與截止前的提醒在裝置上排程，不經過任何伺服器。

### 先試再登入

沒有中正帳號也能用示範帳號看完整個 App，所有資料都是示範用，和自己的帳號分開。

## 隱私

- 登入資料（eCourse2 權杖、校務系統的登入狀態，以及選擇自動登入時的學號與密碼）存放在裝置的
  鑰匙圈，不會同步到 iCloud。
- 讀取過的課表、公告與成績暫存在裝置上，可以在「設定 > 已存資料」查看與刪除；登出時一併刪除。
- App 只直接連線到學校的系統，以及你用到的圖書館查詢、公車動態等服務，資料不會經過開發者。
- 沒有廣告、分析或追蹤。

完整內容請見 [隱私權政策](PRIVACY.md)。

## 下載與安裝

**macOS**：透過 [Homebrew](https://brew.sh) 安裝，之後用 `brew upgrade` 更新。

```bash
brew install --cask koukeneko/tap/tat-ccu
```

也可以從 [最新版本](https://github.com/KoukeNeko/TAT-CCU/releases/latest) 下載
`TAT-CCU-x.y.z-macos.zip`，App 已經過 Apple 公證。

**Android**：從 [最新版本](https://github.com/KoukeNeko/TAT-CCU/releases/latest) 下載
`TAT-CCU-x.y.z-android.apk` 安裝。每個版本都附上 `SHA256SUMS`，可以核對下載的檔案。

**iPhone 與 iPad**：準備上架 App Store。

## 支援的裝置

- iPhone、iPad：iOS 17 以上，含 iPhone Duo 的內外螢幕
- Mac：macOS 12 以上
- Android 手機與平板，含摺疊機
- 介面語言：繁體中文、English、日本語

手機、平板和電腦各有自己的版面：手機用底部的浮動導覽列；iPad 和 Mac 的寬視窗改用側邊欄，清單和
內容並排；摺疊機和 iPhone Duo 沿摺線分頁。

---

## 技術說明

### 登入怎麼運作

App 走 eCourse2 的行動版登入流程：在 App 內的網頁畫面完成單一入口（CAS）登入後，eCourse2 把權杖
交回 App。各校務系統沿用同一個 CAS 登入狀態，所以只需要登入一次。登入畫面由學校的網站提供，App
不會把帳號密碼送到其他地方；選擇自動登入時，學號與密碼只存在裝置的鑰匙圈。

### 開發

需要 Flutter 3.47.7（與 CI 相同）。

```bash
flutter pub get
flutter test
flutter run
```

架構上，頁面在 `lib/ui`，資料存取在 `lib/data`，路由在 `lib/routing`（go_router）。介面字串放在
`lib/l10n` 的 ARB 檔，三種語言要一起更新。

### 發布

推送 `v*` 標籤後，[Release](.github/workflows/release.yml) 會建置 macOS、Android 與 iOS，上傳 iOS 到
TestFlight，建立 GitHub Release 並更新 Homebrew cask。版本說明放在 [`distribution`](distribution)：
`release-notes/vX.Y.Z.md` 是 GitHub Release 的說明，`whatsnew/` 是商店的「新功能」。

<p>
  <a href="https://github.com/KoukeNeko/TAT-CCU/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/KoukeNeko/TAT-CCU/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=CI"></a>
  <img alt="Flutter" src="https://img.shields.io/badge/FLUTTER-3.47.7-02569B?style=for-the-badge&logo=flutter&logoColor=white">
</p>

## 第三方資源

介面字型為 LINE Seed TW 與 LINE Seed JP，採用 SIL Open Font License（見 `assets/fonts`）。
