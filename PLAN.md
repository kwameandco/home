# Home planner — research findings & phased plan

Personal Android app for planning rooms and buildings (bedroom, bathroom, gym, pool…) at true scale, using the
real products I intend to buy, with prices and buy links. Accuracy target: 3D models good enough to use as a
reference image.

_Researched 2026-11-19._

## 1. Verified findings (tested, not just read)

| Question | Result |
|---|---|
| IKEA search works without a key? | **Yes.** `sik.search.blue.cdtapps.com/gb/en/search-result-page?q=…` returns name, type, price, product URL and image. |
| IKEA dimension text usable? | **No.** `itemMeasureReferenceText` is sometimes `"240x57x221 cm"`, sometimes `"Standard Double"`. Use the product page's measurements tab instead (it shows labelled values, e.g. Length 199 / Width 150 / Height 100 cm). |
| IKEA 3D models obtainable? | **Yes.** The product page HTML links GLBs on `web-api.ikea.com/dimma/assets/...` at three quality levels (`isp1`/`isp2`/`isp3`), each also in a Draco version. MALM bed: isp1 = 2.6 MB / 50k verts; isp3 = 7.0 MB. |
| IKEA models true to scale? | **Yes, exactly.** MALM bed GLB bbox = 1.501 × 1.004 × 1.990 m vs. listed 150 × 100 × 199 cm. Y-up, origin at floor centre. No rescaling needed. |
| IKEA model quality as reference? | **Good.** The slats, side rails and headboard are all modelled ([test render](docs/research/ikea-malm-render.png)). |
| Base project | **openPlan3D** (MIT, SvelteKit + three.js, very active, last merge 2026-11-14). It has walls, doors and windows, multiple floors, stairs, 2D + 3D, GLB import (reads size from the model's bounding box), and saves projects locally in IndexedDB. Firebase is used only for sharing and handoff. |
| openPlan3D on a phone? | It has a mobile layout at Pixel 7 size, but it's desktop-first (the empty-room hint says "Draw walls with **W**"). Android touch editing isn't qualified upstream. **This needs testing on my real phone first.** |
| Claude editing plans | openPlan3D has an MCP "agent bridge" for live edits, but **only on the dev server and only from the same machine**. It can't reach a phone. So the route for Claude is: write files (project JSON / GLBs / catalog) that the app imports or syncs. |

Rejected: Pascal Editor (BIM-scale, too heavy), sims-house-builder (no GLB furniture import), blueprint3d and
react-planner (dead), Sweet Home 3D Mobile (closed and paid), Placera API (IKEA staff only), a native Kotlin app (no base to build on).

## 2. Model sourcing for non-IKEA items (desk research)

Almost no other retailer offers a downloadable GLB. Pipeline, best option first:

1. **Product page has a GLB**: Shopify stores (many direct-to-consumer gym and furniture brands) expose it in `<model-viewer src=…glb>`.
2. **Exact W×D×H from the spec table**: always captured. Every later step is scaled to it.
3. **Manufacturer CAD/BIM**: bathroom brands (Hansgrohe, Duravit, Grohe) and some gym brands (Life Fitness) via BIMobject or their pro portals. Dimensionally exact but untextured. Convert IFC/FBX/OBJ → GLB (`IfcConvert`, `FBX2glTF`). Avoid SKP (no Linux converter).
4. **Sketchfab**: there's a free API to search downloadable CC-licensed models by brand and model name.
5. **AI image-to-3D from 2–5 product photos**: Meshy / Tripo / Rodin multi-image, roughly $0.30–1.20 per model. Then decimate and scale **non-uniformly** to W×D×H. TRELLIS.2 (MIT) is the free option but needs a 24 GB GPU. Hunyuan3D's open weights exclude the UK.
6. **Parametric model** (boxes and cylinders from the spec sheet): best for power racks, benches, shelving and cabinets, where AI meshes merge thin parts.

Honest limit: options 5 and 6 look right but aren't exact. Options 1–4 are exact or close.

## 3. Stack

- openPlan3D fork (SvelteKit, three.js) wrapped in **Capacitor**, installed as a sideloaded APK.
  - `CapacitorHttp` gets round CORS, so the app can fetch IKEA and other retailer pages directly with no proxy server.
  - GLBs are cached on the phone's own file system rather than in the WebView's IndexedDB, which can't be guaranteed to persist.
  - Android share-sheet target: share a product link from Chrome or the IKEA app → item added.
- Optimise on import with `gltf-transform` (meshopt + WebP). openPlan3D caps a project at 64 MiB and a single GLB at 16 MiB, so raw IKEA models would fill a whole-house project quickly.
- Rendering: HDRI environment, one soft shadow light, AO, plus an optional path-traced "still render" button (`three-gpu-pathtracer`, already a dependency).
- Fork hygiene: keep `upstream` as a remote and put my additions in new folders (`src/lib/home/…`) to keep merge conflicts small. Generic fixes (e.g. Android touch) can go upstream as pull requests.

## 4. Phases

Each phase ends with something usable on the phone.

### Phase 0 — Validate on the real phone (≈15 min, me)
- Open the hosted openPlan3D on the Android phone. Draw a room, add a door, place furniture, switch to 3D.
- Report what's painful. **Go/no-go for the fork.** If touch editing is unusable, fall back to building my own editor on its geometry code.

### Phase 1 — Fork + Android app shell
- Fork into this repo with upstream tracking. Remove analytics and the Firebase sharing (projects stay local).
- Capacitor wrapper, debug APK built in CI (GitHub Actions artifact) → sideload.
- Fix the Android touch problems found in Phase 0. Make metric units the default.
- **Done when:** my real bedroom is drawn from tape measurements on the phone, with built-in furniture, in 2D and 3D.

### Phase 2 — Product importer (IKEA first)
- "Add product": paste or share a URL → fetch page → GLB (default isp1, isp3 on request), measured W×D×H, price, image, link.
- Check the model's bounding box against the listed size and flag differences over 2 cm. Optimise, then save to a personal catalogue on the device.
- Search IKEA from inside the app.
- **Done when:** sharing an IKEA link from Chrome puts the correctly sized model into the room.

### Phase 3 — Shopping list & budget
- Per item: qty, price, link, status (owned / planned / bought), notes. Totals per room, floor and project.
- Price refresh for IKEA. Export to CSV.
- **Done when:** the bedroom plan shows what it'll cost and one-tap buy links.

### Phase 4 — Everything that isn't IKEA (Claude-made items)
- Generic retailer import: Shopify/model-viewer GLB if present, otherwise W×D×H + photos → box placeholder.
- **Catalogue packs:** I ask Claude for items ("Rogue RML-490 rack", "Duravit ME by Starck WC"). Claude produces GLB + JSON in this repo (from BIM/Sketchfab/AI/parametric, scaled to spec) and the app syncs the pack from a URL.
- A parametric generator in the app for racks, benches, shelving, cabinets, vanities and baths.
- **Done when:** the gym room contains my actual rack, bench and treadmill at true size.

### Phase 5 — Reference-image quality
- HDRI lighting, soft shadows, AO, real floor, wall and tile materials (e.g. bathroom tiles at real tile size).
- "Still render" button (path-traced, progressive). Saved camera views per room.
- **Done when:** a render of the bedroom is good enough to judge colours and proportions.

### Phase 6 — Gym & bathroom planning aids
- Clearance zones attached to items: barbell path, treadmill run-off, door swing, WC/shower clearances, ceiling height for overhead lifts. Warnings when they overlap.
- **Done when:** the plan flags a rack too close to the wall.

### Phase 7 — Whole building, outdoors & pool
- Multiple floors are already in the base: stairs, floor-to-floor alignment.
- Pool and garden: try the sibling OpenLandscape3D (same makers, same file format) before building a recessed-pool feature.
- **Done when:** house + garden + pool in one project.

### Phase 8 — AR check (optional)
- WebXR: place a single item at 1:1 in the real room. Expect a few cm of error, so it's a visual check, not a measurement.

## 5. Risks

- IKEA endpoints and page markup are unofficial and can change → keep the scraper isolated and fail gracefully to a manual-dimensions item.
- IKEA models are probably CC BY-NC-SA → personal use only. Fetch on demand and don't bulk-scrape.
- Upstream openPlan3D moves fast → merge upstream regularly. Larger rewrites of upstream code make merging harder.
- AI-generated models can get proportions wrong → always scale to W×D×H, and parametric models stay the fallback for gym kit.
