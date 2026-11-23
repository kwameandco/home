# Resume note — home planner app

_Parked 2026-11-23. Read this, then `PLAN.md`._

## Where we are
- **Research done; no app code yet.** Plan, findings and phases are in `PLAN.md`; the IKEA test render is in `docs/research/`.
- Branch: `gary-oak/stoic-fermi-dwhwrv` (repo `kwameandco/home`). Everything committed and pushed. No PR.
- Decisions made:
  - Base the app on a fork of **openPlan3D** (MIT, SvelteKit + three.js): https://github.com/laanlabs/openPlan3D
  - Package it as an Android app with **Capacitor**, installed by sideloading the APK (not via the Play Store).
  - IKEA products: get the 3D model from the product page (proven exact to scale), and dimensions/price/link from the page.
  - Non-IKEA items, best option first: a model on the product page, manufacturer BIM files, Sketchfab, AI photo-to-3D scaled to W×D×H, or a simple model built from the spec sheet.

## Blocking next step (Kwame)
**Phase 0:** open https://app.openplan3d.com in Chrome on your Android phone.
1. Draw a room.
2. Add a door.
3. Place furniture.
4. Switch to 3D.

Note what's painful. That decides **go** (fork openPlan3D, as planned) or **no-go** (build our own editor using its geometry code).

## To resume, tell Claude
> Resume the home planner. Read NEXT_SESSION.md and PLAN.md. Phase 0 result: <what was good / painful on my phone>. Start Phase 1.

## Things that were NOT kept (scratch only, rebuild if needed)
- Local clones of openPlan3D and threejs-sims-house-builder.
  - Re-clone openPlan3D with `git clone https://github.com/laanlabs/openPlan3D`.
  - `npm ci && npx vite dev` works with no other setup.
- IKEA GLB downloads and the three.js render harness. Rerun the IKEA check with `tools/ikea-probe.sh "malm bed"`.

## Facts worth remembering
- IKEA search API: `https://sik.search.blue.cdtapps.com/gb/en/search-result-page?q=…&types=PRODUCT`.
  - No key needed.
  - Its `itemMeasureReferenceText` is unreliable: it can be "Standard Double" instead of centimetres.
- IKEA GLBs come from `web-api.ikea.com/dimma/assets/<itemNo>/…/{isp1,isp2,isp3}/{glb,glb_draco}/….glb`.
  - They are in metres, Y-up, with the origin at floor centre.
  - Size: MALM bed isp1 is 2.6 MB and 50k vertices.
- openPlan3D limits: 16 MiB per GLB and 64 MiB per project, so optimise models on import (meshopt + WebP).
- openPlan3D's MCP "agent bridge" only works on a local dev server. Claude can't drive the phone app live, so Claude delivers items as files or catalogue packs.
- Risks: IKEA endpoints are unofficial and can change, and IKEA models are likely CC BY-NC-SA (personal use only).
