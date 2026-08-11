# Memories

### Moments that live on a sticker.

**Memories** turns ordinary NFC stickers into private photo albums.  
Tap a sticker with your iPhone — and the trip, the story, and every photo open instantly.

Stick one on a **fridge magnet**, a **postcard**, a **journal cover**, a **gift box**, or the back of a **souvenir**.  
Wherever the sticker is, the album follows.

---

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-black?style=for-the-badge" alt="iOS 17+" />
  <img src="https://img.shields.io/badge/NFC-NDEF-C4662E?style=for-the-badge" alt="NFC" />
  <img src="https://img.shields.io/badge/SwiftUI-Native-0A84FF?style=for-the-badge" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Stickers-%2420-2D6A4F?style=for-the-badge" alt="$20 stickers" />
</p>

---

## How it works

```
  ┌─────────────┐       tap        ┌─────────────┐       opens       ┌──────────────────┐
  │  NFC sticker │  ─────────────►  │    iPhone   │  ─────────────►  │  That album only  │
  │  (on fridge, │                  │   Memories  │                  │  photos · story   │
  │   magnet…)   │                  │     app     │                  │  map · moments    │
  └─────────────┘                   └─────────────┘                   └──────────────────┘
```

1. **Create an album** in the app — photos, title, story, place, dates  
2. **Write it to a sticker** (or link a sticker you already own)  
3. **Anyone with the app** taps the sticker and sees *only that album*  
4. Stick it anywhere — fridge, magnet, gift, scrapbook, luggage tag  

Each sticker is a key. One sticker → one memory album. Clean, personal, physical.

---

## Buy NFC stickers — $20

Get a pack of writable NFC stickers made for Memories.

| | |
|---|---|
| **Price** | **$20** |
| **What you get** | NFC stickers ready to link to your albums |
| **Use them on** | Fridge magnets, postcards, journals, gifts, walls, souvenirs — anything flat |
| **Compatible** | Standard NTAG / NDEF stickers · iPhone 7 and later |

> Stick a magnet on the fridge. Stick the NFC on the magnet.  
> Guests (or future you) tap with their phone and open the trip.

*Contact the project owner to order a pack — stickers ship ready to write from the app.*

---

## What you can do

### Create albums
Build travel and life albums with photos, a written story, location, date range, and steps along the way. Polaroid-style cards on a warm cream board. A 3D globe at home with pins for every place you’ve been.

### Link stickers
Write an album onto an NFC sticker in seconds. Rewrite or unlink anytime from the Tags screen. Each sticker stays tied to its own album.

### Open with a tap
Hold the top of your iPhone to the sticker. The app opens straight into that memory — not a feed, not a list — **that sticker’s album only**.

### Put stickers anywhere
- Fridge magnets  
- Photo frames  
- Scrapbooks & journals  
- Gift boxes & wedding favors  
- Suitcases & camera straps  
- Postcards from the trip itself  

The physical object becomes the interface.

---

## The app at a glance

| Screen | What it feels like |
|--------|--------------------|
| **Home** | Night sky + 3D globe, terracotta pins, one-tap scan |
| **Board** | Cream polaroid wall, tape accents, year filters |
| **Detail** | Map header, hero photo, story, share & NFC write |
| **Scan** | Hold phone to sticker → album opens |
| **Tags** | Manage which sticker points to which album |
| **Create** | Guided flow: places → photos → story → done |

Warm clay journal aesthetic — paper, terracotta, soft type. Not neon. Not SaaS chrome.

---

## Quick start

### Requirements
- **Xcode 15+** (full Xcode from the Mac App Store)
- **iPhone 7+** for real NFC (Simulator has a mock scan path)
- Apple ID for signing (Personal Team is fine for device install)

### Open the project

```bash
open Memora/Memora.xcodeproj
```

1. Select the **Memora** target → **Signing & Capabilities**  
2. Choose your **Team**  
3. Plug in your iPhone → Run ▶  

First launch: **Continue as Guest** is the fastest path. Demo memories load automatically so you can feel the product immediately.

---

## NFC flow (in practice)

1. Create a memory (photos → details → save)  
2. Open the memory → **Write to NFC sticker**  
3. Hold the top of the iPhone to the sticker  
4. Sticker stores a short link: `memora://m/{SHORTID}`  
5. Later: **Scan** (or just tap the sticker) → that album only  

On the **Simulator**, scan injects demo code `ROME26` and write succeeds in mock mode.

> Free Apple Developer accounts can still use the hybrid path: write URLs with free NFC tools if needed; the app opens albums via the deep link when iOS reads the tag.

---

## Project layout

```
nfc_album/
├── README.md                 ← you are here
└── Memora/
    ├── Memora.xcodeproj
    ├── DESIGN.md             # clay journal design system
    ├── supabase/             # schema / migrations
    └── Memora/
        ├── App/              # entry, tabs, config
        ├── Theme/            # terracotta · cream tokens
        ├── Models/           # Memory, tags, sample data
        ├── Services/         # Auth, store, Core NFC
        ├── Views/            # Home · Board · Scan · Tags · Create
        └── Resources/        # entitlements, assets, plist
```

---

## Stack

| Piece | Choice |
|-------|--------|
| UI | SwiftUI |
| Maps / trips | Mapbox (in-app) + SceneKit globe |
| NFC | Core NFC + system NDEF URL deep links |
| Backend (optional) | Supabase for cloud memories |
| Auth | Sign in with Apple · Google · Guest |

Local-first works out of the box — no account required to start.

---

## Optional setup

<details>
<summary><strong>Google Sign-In</strong></summary>

1. [Google Cloud Console](https://console.cloud.google.com/) → OAuth client ID → **iOS**  
2. Bundle ID: `com.smohanty.memora`  
3. Paste into `Memora/Memora/App/Config.swift`:

```swift
static let googleClientID = "YOUR_ID.apps.googleusercontent.com"
```

4. Add the reversed client ID as a URL scheme in Xcode → Target → Info → URL Types  

</details>

<details>
<summary><strong>Mapbox</strong></summary>

Public token lives in `Config.swift`. Trip maps use Mapbox GL in a `WKWebView`.  
The home globe is native SceneKit and works offline.

</details>

---

## Why this exists

Phones bury photos. Cloud links rot.  
A sticker on the fridge doesn’t.

Memories is for people who keep **things** — magnets, tickets, postcards — and want those things to open a real album, not another app home screen.

**$20 stickers. Your albums. Tap to remember.**

---

<p align="center">
  <sub>Independent personal project · Moments Forever aesthetic, not affiliated with Moments Forever GmbH</sub>
</p>
