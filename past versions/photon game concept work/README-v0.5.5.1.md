# ASCII Photon — CHANGELOG

This file lists meaningful changes since the first laser prototype. Dates are ISO-ish because time is fake.

---

## v0.5.5 — Laser (Excitation Emission) — 2025-10-04
**Core:** Photons excite **objects**, and **waves radiate from the excited object**, not the path or the photon.

- Added target atoms/molecules with labeled **resonant wavelengths** (Na 589 nm, Cl₂ 520 nm, Hg 436 nm, O₂ 760 nm).
- On photon hit, object flashes and spawns an emission ring + core + glow at the object’s coordinates.
- **Resonance scaling:** brightness = exp(−Δλ² / 2·tol²). Off-resonance still scatters weaker.
- Photon is consumed on hit; no path glow remains.
- HUD shows counts for live photons and emission rings.

**Controls (unchanged):**
W/A/S/D aim · Arrow keys move · Space tap=single, hold=stream · T toggle fire · 1..5 λ presets · -/= fine-tune · G toggle drain · R reset

**Tech:** line-segment proximity test (radius ≈ 0.8 cells) detects hits; emission lifetime ≈ 1.2 s; ring speed ≈ 14×speedScale(λ).

**Known limits:**
- Emission re-emits at **incoming λ** (no Stokes shift yet).
- No occlusion or surface normals; everything is a friendly circle.
- Atom positions are static demo spots.

---

## v0.5.4 HOTFIX — Laser (Photon-centric) — 2025-10-04
**Fix:** initialization order guard so the canvas can’t clamp a laser that doesn’t exist yet.  
Same feature set as v0.5.4 below.

## v0.5.4 — Laser (Photon-centric waves) — 2025-10-04
**Core:** Tap Space fires **one photon**; hold/toggle streams. Each photon is a moving source with a bright core, expanding ring, and soft glow.  
**Removed:** path-based beam. Goodbye onion-skin artifacts.

---

## v0.5.3 — Laser (Idle Glow Off) — 2025-10-04
**Core:** Active beam glow is **disabled when idle**. No visual unless actually firing.  
Dev knob: `idleGlowScale` if you want faint idle later.

---

## v0.5.2 — Laser (WASD Aim + Glow) — 2025-10-04
**Core:** **WASD aims**, **arrow keys move**. **Persistent beam** replaces stacked paths. Added **illumination glow** around beam.  
Residual pulses kept for flavor.

---

## v0.5.1 — Laser Prototype (hotfix) — 2025-10-04
**Fix:** init order (fitCanvas vs Laser) and added a crosshair at spawn.

## v0.5.0 — Laser Prototype — 2025-10-04
**Core:** WASD move (then), Q/E rotate, Space fire/hold, battery drain scales with 1/λ, presets + fine tuning, ASCII wavefronts.

---

## Roadmap (next obvious steps)
- **Fluorescence:** absorb at λ_in, emit at longer λ_out per object, with lifetimes (ns/µs) mapped to frames.
- **Quenching/saturation:** prevent infinite spam on one atom; add recovery time and power broadening.
- **Level objective:** power N sensors by exciting the correct species at the correct λ to open an exit.
- **Optics comeback:** bring back polarizers/splitters as placeables that interact with photon paths pre-hit.
- **Config:** inline JSON for object lists, λ, tolerances; URL seed for reproducible layouts.

## Performance knobs
- Max photons: 40 (raise cautiously). Emission life: ~1.2 s. ASCII threshold: 0.06. Glow/ring sigmas in `Emission` class.
- Shrink window to cut grid size; lower lifetimes if you raise the fire rate.


---

## v0.5.5.1 — Hotfix (Excitation Emission) — 2025-10-04
- Added **aim preview** dotted ray (toggle with **H**) so you always see where the laser points.
- **Photon glyphs brighter** with a tiny trail.
- **Wall scatter:** if a photon misses all targets and reaches a boundary, it creates an emission at the wall so you still get feedback.
- **Battery helper:** press **B** to refill instantly. HUD shows “BATTERY EMPTY” hint when applicable.
- Kept object excitation model; emission still radiates from the **hit object**.
