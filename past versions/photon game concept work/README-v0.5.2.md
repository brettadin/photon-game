# ASCII Photon — v0.5.2 Laser (WASD Aim + Glow)

This build turns the prototype into a playable "laser" sandbox with **WASD aiming**, **arrow-key movement**, a **persistent beam** (no trail artifacts), and **illumination** around the beam.

**File:** `ascii-photon-v0.5.2-laser.html`  
**Engine:** HTML5 Canvas + JS (single file, no deps)  
**Resolution:** ASCII grid (dynamic, sized to window)  

---

## Quick start
1. Open `ascii-photon-v0.5.2-laser.html` in a modern browser.  
2. Use the controls below. If you see a blank screen, resize the window once or press **R** to reset.

---

## Controls

| Action | Key(s) |
|---|---|
| Aim | **W/A/S/D** (diagonals by holding two) |
| Move | **Arrow keys** |
| Fire | **Space** (tap or hold) |
| Toggle continuous fire | **T** |
| Wavelength presets | **1..5** → 700/600/500/400/320 nm |
| Fine-tune wavelength | **-** / **=** (±5 nm) |
| Toggle energy drain | **G** |
| Reset | **R** |

HUD shows λ, approximate tempo scale, fire mode, drain mode, and a battery bar.

---

## Mechanics

### Persistent beam
Holding fire creates a single **active beam** that updates as you aim or move. This eliminates the onion-skin trail effect from earlier builds. The beam draws:
- a **core** (narrow Gaussian around the path), and
- a **glow** (longer exponential falloff) to simulate illumination.

### Residual pulses
While firing, small, short-lived **wavefront rings** are emitted at a limited cadence for motion texture. They fade quickly and do not accumulate.

### Battery / energy
- Battery drains faster for **shorter wavelength** (higher frequency), approximated by a bounded **1/λ** curve.
- Battery **recharges** slowly when not firing.
- Press **G** to toggle drain for testing.

---

## Tunable parameters (inside the file)

Search the source for these symbols to adjust game feel:

### Laser
- `fireRate` (float, shots/sec baseline for residual pulses; affects drain rate)
- `batteryMax`, `rechargePerSec`
- `costPerShot(nm)` (function; adjusts 1/λ curve min/max)

### ActiveBeam
- `coreSigma` (float, beam core thickness in cells; default `0.45`)
- `glowReach` (float, illumination reach in cells; default `12.0`)
- `glowStrength` (0..1, glow intensity; default `0.45`)
- `rippleHz` (visual shimmer speed)

### Rendering
- ASCII ramp: ` .:-=+*#%@`  
  Use more dense chars (`% @`) for a brighter look or remove dense chars for a softer look.
- Glow threshold: `if (amp > 0.06)`; lower for more ambient light, raise for crisper lines.

Performance tips: reduce `rows/cols` by shrinking the window, or shorten lifetimes (`Wavefront.life`) if you raise `fireRate`.

---

## Differences vs v0.5.1
- Aim moved to **WASD**; rotation keys removed.
- Movement on arrow keys (strafe while aiming).
- **Active beam** replaces per-shot stacked paths → **no trail outlines**.
- Added **illumination glow** with adjustable reach/strength.
- Shorter-lifetime residual pulses for visual interest.
- Minor battery/drain tuning.

---

## Known limits
- No level geometry yet (polarizers, splitters, etc.) in this specific build; it’s a clean aiming/shooting sandbox. Those return in future versions.
- Browser font metrics for monospaced fonts can vary slightly; if glyph alignment looks off, try a different zoom level or window size.

---

## Troubleshooting
- **Blank screen**: press **R** or resize the window. This forces grid recalc and repositions the emitter.
- **Low FPS**: reduce the window size, or increase `amp` thresholds to draw fewer characters.
- **Too bright/dim**: tune `glowStrength` or edit the ASCII ramp (swap `:` for `-`, add/remove `%`/`@`).

---

## License
Use, modify, and ship it. Attribution appreciated but not required.
