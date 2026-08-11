# Memories

### Moments that live on a sticker.

> Full product README lives at the repo root: **[../README.md](../README.md)**

**Memories** is a native SwiftUI app: NFC sticker → short link → photo/story album.

- **Buy NFC stickers for $20** — stick them on fridge magnets, gifts, journals, anything  
- **Create albums** in the app with photos, story, place, and map  
- **Tap a sticker** → open *that sticker’s album only*

```bash
open Memora.xcodeproj
```

### Make it run (summary)

1. Open the project in **Xcode 15+**  
2. Set your Mapbox **public** token in `Memora/App/Config.swift` (`mapboxAccessToken = "pk.…"`) — do not commit real tokens  
3. **Signing & Capabilities** → choose your Team  
4. Run on Simulator or a physical iPhone  
5. First launch → **Continue as Guest** (demo memories load automatically)

**Real NFC** needs a paid Apple Developer account + NFC Tag Reading entitlement.  
**Your own backend** → apply `supabase/migrations/…` and update Supabase URL/anon key in `Config.swift`.

Full checklist (Mapbox, NFC free vs paid, Supabase, Google Sign-In, troubleshooting):  
**[../README.md](../README.md)#make-it-run-setup-checklist**
