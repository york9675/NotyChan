![header](https://capsule-render.vercel.app/api?type=waving&height=300&color=gradient&text=NotyChan&animation=blink)

<p align="center">
  <a href="#License" target="_blank">
    <img alt="License" src="https://img.shields.io/github/license/york9675/NotyChan?logo=github&style=for-the-badge" />
  </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
    <img alt="Swift" src="https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white" />
  </a>
  <a href="https://www.apple.com/ios" target="_blank">
    <img alt="iOS" src="https://img.shields.io/badge/iOS-17.0+-000000?style=for-the-badge&logo=ios&logoColor=white" />
  </a>
</p>

<p align="center"> 
  <a href="README.md">English</a> 
  ·
  <b>繁體中文</b>
</p>

---

**NotyChan** 是一款美觀、輕量且注重隱私的 iOS 筆記應用程式。

- 🌈 完全自訂的豐富文字編輯器  
- 🖼️ 每則筆記皆有專屬圖片庫與描述  
- 🔐 使用 Face ID / Touch ID 保護筆記與資料夾  
- 📂 以資料夾方式管理  
- ⌚ 支援 Apple Watch（目前僅可讀取）  
- 💡 完全免費、開源、無廣告  
- 📶 完全離線運作 — 無需帳號、無追蹤  

> [!WARNING]\
> 此專案仍在開發中。

> [!NOTE]  
> 此應用程式由於開發者無法負擔那個貴死人的蘋果開發者計劃會費，因此未上架App Store，需要自行使用Xcode安裝到您的裝置上。歡迎透過下方Buy Me a Coffee按鈕贊助開發者，感謝！

---

## 📷 螢幕截圖

(待補)

---

## 🚀 功能特色

### ✍️ 富文字編輯器
- 自訂字體、字體大小與顏色（前景 + 背景）  
- 文字格式：**粗體**、*斜體*、~~刪除線~~、<ins>底線</ins>  
- 對齊選項：靠左、置中、靠右、左右對齊  

### 🖼️ 筆記圖片庫
- 每則筆記都有獨立的圖片庫  
- 從相簿或相機新增照片  
- 為圖片新增簡單描述  

### 🔐 安全性
- 可使用 Face ID 或 Touch ID 鎖定單一筆記或資料夾  
- 最近刪除的筆記（30 天後自動刪除）  

### 📁 管理方式
- 建立資料夾來分組筆記  
- 在資料夾間移動筆記  
- 置頂筆記  
- 依標題或最後修改時間排序（A-Z 或升序 / 降序）  

### 🔎 效率工具
- 全文檢索（資料夾 + 筆記）  
- 離線支援 — 不需網路  
- 匯出 / 分享為純文字  
- 筆記封存  
- Apple Watch 應用程式（僅能檢視已同步的筆記）  

---

## 🎯 為什麼選擇 NotyChan？

不同於許多現代筆記應用程式，NotyChan 擁有：

- **真正免費** – 無訂閱、無廣告、無追蹤。  
- **開源** – 完全透明，您可以閱讀、分支或貢獻程式碼。  
- **離線優先** – 無雲端綁定，筆記僅存在於您的裝置中。  

---

## 📦 計劃中的功能

- [ ] 改善筆記封存功能  
- [ ] 改善富文字編輯器  
- [ ] iCloud 同步（需付費 Apple 開發者帳號）  
- [ ] App Store 上架（需付費 Apple 開發者帳號）  
- [ ] 更多功能待開發...

---

## 🛠️ 建置與執行

> [!NOTE]  
> 執行 iOS 專案需要 Xcode 與 macOS 系統。

1. 複製此專案：
```bash
git clone https://github.com/york9675/NotyChan.git
cd NotyChan/src
````

2. 在 Xcode 中開啟 `NotyChan.xcodeproj`。

3. 在模擬器或實體裝置上建置並執行。

---

## 🤝 貢獻

歡迎 Pull Request、回饋與問題回報！

* 請查看 [Issues](https://github.com/york9675/NotyChan/issues) 了解已知問題或點子
* 遵循標準的 [fork → commit → PR](https://guides.github.com/activities/forking/) 工作流程
* 若是重大更動，請先開啟討論

---

## 📄 許可證

該項目已獲得 MIT 許可證的許可。有關更多詳細資訊，請參閱許可證文件。

## 💪 支持

當我開始開發應用程式時，我的目標很簡單：創造出真正有幫助的應用程式並免費提供給大家。在這個充滿付費功能和廣告的世界中，我希望能建立一些任何人都能免費使用的東西，單純只是為了讓生活更方便。我開發的應用程式一直都是無廣告的，而且像這個專案一樣，有些甚至是開源的。如果我的應用程式能夠幫助哪怕是一小部分人提高效率或解決問題，那就值得了。

然而，作為一名學生和獨立開發者，我面臨了一些財務上的挑戰。每年3000多台幣的 Apple 開發者計劃會費成為了一個不小的障礙。這個會員資格是解鎖一些 iOS 功能（如具時效性通知）並將應用程式發布到 App Store 所必需的。不幸的是，這是我目前無法負擔的成本。我甚至不得不使用 Hackintosh 進行開發，因為我沒有能力購買 Mac。

儘管面臨這些挑戰，我依然承諾讓這款應用程式保持**完全免費**——不會有廣告或應用內購買。但是，為了讓應用程式功能完善並對 iOS 用戶完全開放，我需要一些資助來支付 Apple 開發者帳戶的費用。

### 如何支持

如果你認同這個專案並希望幫助它成長，以下是幾種支持的方式：

- **捐款：** 無論金額大小，都將幫助我支付每年的 Apple 開發者費用。你可以透過下方的 [Buy Me a Coffee](https://buymeacoffee.com/york0524) 按鈕贊助這個專案！
- **分享：** 將這個專案分享給你的朋友、家人，或任何可能受益或支持的人！
- **合作：** 如果你是開發者、設計師，或者有改進建議，歡迎透過創建Issues、提交 Pull Requests或改善文件來為這個專案做出貢獻！

無論你選擇如何支持，這都將幫助我解鎖這款應用程式的全部潛力，並保持它對所有人免費。感謝你幫助我維持這個願景的實現！

<p><a href="https://www.buymeacoffee.com/york0524"> <img align="left" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="50" width="210" alt="york0524" /></a></p><br>

或者，您也可以簡單的給顆 :star: ！

_感謝你抽出時間閱讀，並感謝你提供的任何支持。讓我們一起改善這款應用程式，幫助更多的人！_

## ⭐ 星星歷史

[![Star History Chart](https://api.star-history.com/svg?repos=york9675/NotyChan\&type=Date)](https://star-history.com/#york9675/NotyChan&Date)

---

© 2025 York Development

在台灣以 \:heart: 與 Swift 打造。

(目前此繁中版README使用機器翻譯，之後有空再潤潤吧，哈哈。)