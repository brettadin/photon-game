# ASCII Photon — Versioning & Notes

This repo of one-file demos is evolving into a small game. Here's the sane naming and version plan, plus controls and notes.

## Versioning scheme
`ascii-photon-vMAJOR.MINOR[-tag].html`

- **MAJOR**: big mechanic or rendering change.
- **MINOR**: additive features, tweaks, perf passes.
- Optional **tag** to clarify purpose, e.g. `-laser`, `-lab`, `-perf`.

## Existing files mapped to versions
- `ascii_photon_demo.html` → **v0.1 — Blink & Wavefront**. Click-to-blink, expanding path ring.
- `ascii_photon_demo_plus.html` → **v0.2 — Polarizer & Splitter**. Malus gate; splitter with dual detectors.
- `ascii_photon_demo_perf.html` → **v0.3 — Perf Pass**. Snap-back, cap, bounding boxes.
- `ascii_photon_demo_advanced.html` → **v0.4 — Advanced Lab**. Long-pass filter ghost, Michelson node, integrator.
- `ascii-photon-v0.5-laser.html` → **v0.5 — Laser Prototype**. WASD + rotation + continuous fire + battery + live wavelength tuning.

## v0.5 — Laser Prototype (this build)
- **Move**: `WASD`
- **Rotate**: `Q`/`E`
- **Fire**: `Space` to fire; hold for continuous. `T` to toggle fire on/off.
- **Wavelength**: `1..5` presets at 700/600/500/400/320 nm. Fine-tune with `-` / `=` (±5 nm).
- **Energy**: battery drains **faster** at **shorter λ** (higher frequency). Recharge slowly when not firing.
  - Toggle drain for testing: `G`.
- **Reset**: `R`.

### Balance knobs (inside the file)
- `fireRate` (shots/s), `life` (wave ring seconds), `batteryMax`, `rechargePerSec`, `costPerShot()` curve, and `speedScale()` tempo mapping.
- ASCII density ramp is ` .:-=+*#%@`. Tighten/loosen by adding/removing glyphs.

## Roadmap (short, real, shippable)
- **v0.6 — Obstacles & Optics**: place polarizers, slits, splitters as interactables in the laser world. Collisions optional; interactions respond to wavefront crests.
- **v0.7 — Level goals**: simple objective (open exit by powering N sensors) and a UI-free end-state.
- **v0.8 — Save/load & config**: URL params or inline JSON for tuning values. Optional seed for obstacle layouts.
- **v0.9 — Packaging**: trim, comment, and ship a minified build plus a readable dev build.

## Known limits
- ASCII via canvas is fast enough, but massive windows can tank FPS. Lower grid (`cols/rows`) or ring `life` if needed.
- No collision map yet; optics are cosmetic props until v0.6.

## License
Use it, tweak it, rebrand it. Credit is nice but not required.


## v0.5.1 — Hotfix
- Fixed init order crash (Laser referenced before init in `fitCanvas`).
- Added emitter crosshair so the start position is obvious.
