---
marp: true
theme: gaia
class: lead
paginate: true
backgroundColor: #fff
color: #1F4A7F
style: |
  section {
    font-family: 'Helvetica Neue', Arial, sans-serif;
  }
  h1 { color: #1F4A7F; font-weight: 800; }
  h2 { color: #1F4A7F; }
  strong { color: #C2185B; }
  section.lead h1 { font-size: 2.6em; }
  section.lead h2 { font-style: italic; font-weight: 400; }
  .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
  .stat { font-size: 2.2em; font-weight: 800; color: #C2185B; }
  .small { font-size: 0.8em; color: #555; }
  table { font-size: 0.85em; }
---

<!-- _class: lead -->

# **Fashion AI**
## Try it on. Style it up. Ship it out.

A Flutter app that turns *"will this look good on me?"* into a one-tap answer.

`#hackathon` `#flutter` `#gemini` `#diffusion`

---

## The Problem

<div class="cols">

<div>

<span class="stat">70%</span>
of online fashion purchases are **returned** — wrong fit, wrong style.

<span class="stat">23 min</span>
average time spent picking an outfit before going out.

</div>

<div>

- Choice paralysis across thousands of items
- No personalization — everyone sees the same grid
- Can't *see it on yourself* before buying
- Style advice is locked behind stylists

</div>

</div>

---

## Our Solution — Fashion AI

A single mobile app that does **three things really well**:

1. **Talks fashion** — chat with an AI stylist that understands photos
2. **Tries it on** — see clothes on *your* body before you buy
3. **Picks for you** — outfit recommendations from a 30-second style quiz

> Built on Flutter • Firebase • Gemini • Diffusion models

---

<!-- _class: lead -->

# Live Demo
## *(switch to the phone)*

1. Browse a brand → tap **Try On**
2. Snap an avatar photo → composite generates
3. Ask **StyleBot**: *"What goes with this?"*
4. Take the **30-second quiz** → see 3 personalized outfits

---

## Feature 1 — AI Fashion Assistant

<div class="cols">

<div>

**StyleBot** — multimodal chat powered by **Google Gemini 2.0 Flash**

- Ask anything: *"office wear for hot weather?"*
- Drop a photo: *"what colors match this?"*
- Pre-baked prompts for one-tap queries
- Auto-extracts shoppable links

</div>

<div>

```
👗 user: how do I style these jeans
       for a night out?
🤖 StyleBot: Pair them with a fitted
       black top and ankle boots.
       Add a leather jacket for edge…
```

</div>

</div>

---

## Feature 2 — Virtual Try-On

<div class="cols">

<div>

Powered by the **Try-On Diffusion** model (RapidAPI).

- Pick clothing from any brand page **or** upload your own
- Snap an avatar photo (camera or gallery)
- EXIF auto-correction + compression for fast uploads
- Photorealistic composite in seconds

</div>

<div>

**Pipeline**

`Asset → temp file → SharedPreferences hand-off`
↓
`Avatar + Clothing → multipart POST`
↓
`Diffusion model → JPEG result`
↓
`Image.memory render`

</div>

</div>

---

## Feature 3 — Outfit Recommendations

<div class="cols">

<div>

Take a **30-second quiz** → get **3 personalized outfits**.

- Dynamic question schema (multi-select with `maxSelections`)
- Item-specific preferences (colors, materials)
- Cached locally for offline re-view
- "View previous recommendations" returning users

</div>

<div>

```json
{
  "outfit_number": 1,
  "components": {
    "topwear":    "Classic White Shirt",
    "bottomwear": "Navy Blue Jeans",
    "footwear":   "Brown Leather Loafers"
  }
}
```

</div>

</div>

---

## Multi-Brand Catalog, Built In

Curated catalogs from **4 partner brands**, browsable by **gender** or **category**:

| Brand | Vibe |
|---|---|
| **Breakout** | Streetwear & casual |
| **Chase Value** | Affordable formals |
| **Ideas** | Premium / formal |
| **Outfitter** | Lifestyle contemporary |

Auto-derived categories: `Shirts` `Pants` `Shoes` `Jackets` `Dresses` `Sportswear` `Formal` `Casual`

---

## Architecture

```
 ┌──── Flutter app (Android / Web-ready) ────┐
 │  UI  ←→  Services  ←→  Models             │
 └─────────────────┬─────────────────────────┘
                   │
   ┌───────────────┼─────────────────────┐
   ▼               ▼                     ▼
 Firebase     Google Gemini       RapidAPI Try-On
 (Auth +      (gemini-2.0-flash)  Diffusion
  Firestore                        +
  + Storage)                      Recommendations
                                   REST API
```

**Client-heavy** • **No server to maintain** • **3 AI services orchestrated**

---

## Tech Stack

<div class="cols">

<div>

**Frontend**
- Flutter 3.6 / Dart
- Material + Convex bottom bar
- `image_picker`, `flutter_image_compress`, `exif`
- `flutter_dotenv`, `shared_preferences`

</div>

<div>

**Backend / AI**
- Firebase Auth, Firestore, Storage
- Google Sign-In
- Gemini 2.0 Flash (multimodal)
- Try-On Diffusion (RapidAPI)
- Custom recommendations REST API

</div>

</div>

---

## What We Built in *N* Hours

- ✅ End-to-end auth (email + Google + anonymous)
- ✅ Onboarding + splash routing
- ✅ Brand & category catalog with **300+ asset images**
- ✅ Multimodal AI chat
- ✅ Working virtual try-on with size/format guards
- ✅ Quiz → API → cached results loop
- ✅ Profile with persisted style preferences

---

## What's Next

| Horizon | Plan |
|---|---|
| **Now** | Move ngrok API to a stable host; iOS Firebase config |
| **Next** | In-app purchase links to brand stores |
| **Later** | AR try-on (3D pose), social outfit sharing, weather/occasion-aware suggestions |
| **Vision** | "Closet OS" — your wardrobe as a queryable database |

---

<!-- _class: lead -->

# **Thanks!**

**Try it. Wear it. Love it.**

`#FashionAI`

📂 Repo: `Fashion-AI` • 🛠 Built with Flutter + Gemini + Diffusion
