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

## Make it run (setup checklist)

Follow these steps on a **Mac**. The app is native SwiftUI — no CocoaPods / SPM install step for the default build.

### 1. Requirements

| Need | Notes |
|------|--------|
| **macOS** | Recent enough for Xcode 15+ |
| **Xcode 15+** | Full Xcode from the Mac App Store (not just Command Line Tools) |
| **Apple ID** | Free Personal Team is enough for Simulator + basic device install |
| **iPhone 7+** | Only required for **real** NFC; Simulator has a mock scan/write path |
| **Mapbox account** | Free tier is fine — needed for trip maps (see step 3) |

Optional later:

- **Paid Apple Developer Program ($99/yr)** — real NFC Tag Reading entitlement  
- **Supabase project** — cloud sync / email auth (local guest mode works without this)  
- **Google Cloud OAuth client** — Google sign-in  

### 2. Get the code

```bash
git clone https://github.com/sm1216/Memora.git
cd Memora
open Memora/Memora.xcodeproj
```

### 3. Set your Mapbox public token (required for maps)

GitHub push protection blocks committed Mapbox tokens, so the repo ships with an **empty** token.

1. Create a free account at [Mapbox](https://account.mapbox.com/)  
2. Create an access token with the default **public** scopes (`pk.*`)  
3. Open `Memora/Memora/App/Config.swift` and set:

```swift
static let mapboxAccessToken = "pk.YOUR_PUBLIC_TOKEN_HERE"
```

4. **Do not commit** this file with a real token. Keep secrets local.

Also (optional, for CLI / server tools only):

```bash
cp Memora/Secrets.local.example Memora/Secrets.local
# edit Memora/Secrets.local — MAPBOX_PUBLIC_TOKEN / MAPBOX_SECRET_TOKEN
# Secrets.local is gitignored. Never put sk.* into Swift that ships on the phone.
```

| Token | Where | Commit? |
|-------|--------|---------|
| Mapbox **public** `pk.*` | `Config.swift` (local only) | No |
| Mapbox **secret** `sk.*` | `Secrets.local` only | Never |
| Supabase **anon** key | Already in `Config.swift` (public client key) | OK for client apps |
| Supabase **service_role** | Never in the iOS app | Never |

Without a Mapbox `pk.*` token, the **home globe still works** (SceneKit). In-app **Mapbox trip maps** will not load tiles until you set the token.

### 4. Signing in Xcode

1. Select the **Memora** target  
2. **Signing & Capabilities**  
3. Check **Automatically manage signing**  
4. Choose your **Team** (Personal Team is fine)  
5. If the bundle ID `com.smohanty.memora` is taken on your team, change **Bundle Identifier** to something unique (e.g. `com.yourname.memora`)

### 5. Run

**Simulator (fastest)**

1. Pick any recent iPhone simulator  
2. Press **Run ▶**  
3. First launch → **Continue as Guest**  
4. Demo memories load so you can explore without backend setup  

**Physical iPhone**

1. Plug in the phone, trust the computer  
2. Select your device as the run destination  
3. Run ▶  
4. On the phone: **Settings → General → VPN & Device Management** → trust your developer certificate if prompted  
5. Allow photo / camera / location prompts when you use those features  

### 6. What works out of the box vs what needs setup

| Feature | Guest + empty Mapbox | After Mapbox token | After paid Apple Dev + NFC entitlement | After your own Supabase |
|---------|----------------------|--------------------|----------------------------------------|-------------------------|
| Browse demo albums | ✅ | ✅ | ✅ | ✅ |
| Create local memories | ✅ | ✅ | ✅ | ✅ |
| Home 3D globe | ✅ | ✅ | ✅ | ✅ |
| Trip Mapbox maps | ❌ blank / no tiles | ✅ | ✅ | ✅ |
| NFC mock (Simulator) | ✅ | ✅ | ✅ | ✅ |
| Real NFC scan/write | ❌ | ❌ | ✅ | ✅ |
| Email / cloud sync | uses bundled Supabase project if reachable | same | same | ✅ your project |

---

## NFC — make real stickers work

### Simulator

- **Scan** injects demo code `ROME26`  
- **Write** succeeds in mock mode (no hardware)

### Free Apple ID (Personal Team)

Real **NFC Tag Reading** entitlement is **not** available on free teams.  
`Memora/Memora/Resources/Memora.entitlements` keeps the NFC keys commented for that reason.

You can still:

1. Create a memory in the app and note its short id / deep link (`memora://m/{SHORTID}`)  
2. Write that URL to a sticker with any free NDEF writer app  
3. Tap the sticker → iOS opens Memora into that album when the app is installed  

### Paid Apple Developer Program (real in-app NFC)

1. Enroll at [developer.apple.com](https://developer.apple.com)  
2. In Xcode → **Signing & Capabilities** → **+ Capability** → **Near Field Communication Tag Reading**  
3. Uncomment the NFC keys in `Memora/Memora/Resources/Memora.entitlements` (or switch to `Memora.nfc.entitlements` if you use that file)  
4. Rebuild on a physical iPhone 7+  

### NFC flow (in practice)

1. Create a memory (photos → details → save)  
2. Open the memory → **Write to NFC sticker**  
3. Hold the **top** of the iPhone to the sticker  
4. Sticker stores a short link: `memora://m/{SHORTID}`  
5. Later: **Scan** (or system tag read) → **that album only**

---

## Optional: Supabase (your own backend)

The app is already pointed at a sample Supabase project in `Config.swift`. To use **your** project:

1. Create a project at [supabase.com](https://supabase.com)  
2. Run the migration SQL:

```bash
# From repo root, with Supabase CLI logged in and linked:
cd Memora
supabase db push
# or paste Memora/supabase/migrations/20260809230000_memora_schema.sql
# into the Supabase SQL editor
```

3. Create a **Storage** bucket named `memories` (public read if you want share links)  
4. Auth → enable **Email** (and optionally Google / Apple)  
5. For local/dev, turn **off** “Confirm email” if you want instant sign-in  
6. Update in `Memora/Memora/App/Config.swift`:

```swift
static let supabaseURL = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
static let supabaseAnonKey = "YOUR_ANON_PUBLIC_KEY"
```

Use the **anon / public** key only. Never put `service_role` in the iOS app.

---

## Optional: Google Sign-In

1. [Google Cloud Console](https://console.cloud.google.com/) → create an **iOS** OAuth client ID  
2. Bundle ID must match Xcode (default: `com.smohanty.memora`)  
3. In `Config.swift`:

```swift
static let googleClientID = "YOUR_ID.apps.googleusercontent.com"
```

4. Xcode → Target → **Info** → **URL Types** → add the **reversed** client ID scheme (`com.googleusercontent.apps.…`)  
5. Enable Google provider in your Supabase Auth settings with the same client  

---

## Permissions the app will ask for

iOS will prompt when features are used (strings live in `Info.plist`):

- **NFC** — read/write stickers  
- **Photo library** — pick album photos (+ optional metadata for date/place)  
- **Camera** — capture new moments  
- **Location (when in use)** — tag memories on map/globe  

---

## Project layout

```
Memora/                       ← repo root
├── README.md                 ← you are here
├── .gitignore
└── Memora/
    ├── Memora.xcodeproj
    ├── DESIGN.md             # clay journal design system
    ├── Secrets.local.example # copy → Secrets.local (gitignored)
    ├── supabase/             # schema / migrations
    └── Memora/
        ├── App/              # entry, tabs, Config.swift
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
| Auth | Email · Google (optional) · Guest |

**Local-first works out of the box** — Guest mode + demo data, no account required to start.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Maps blank / gray | Set `mapboxAccessToken` in `Config.swift` to a valid `pk.*` token |
| Signing errors | Pick a Team; change bundle ID if it’s already used |
| App won’t open on device | Trust the developer cert under **VPN & Device Management** |
| NFC capability missing | Free Personal Team cannot use NFC Tag Reading — use paid program or external NDEF writer |
| Auth / cloud fails | Check Supabase URL + anon key; confirm email setting; RLS policies from migration applied |
| Push rejected for secrets | Never commit `pk.*` / `sk.*` / `Secrets.local` — keep tokens local only |

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
