# ASCII Photon — v0.5.4 Laser (Photon-centric waves)

**What’s new**
- **Tap = single photon.** Press **Space** once to emit one photon. Hold Space or toggle fire to emit a stream at `fireRate`.
- **Waves radiate from each photon, not the path.** Each photon is a moving source:
  - bright **core** at its position,
  - an expanding **ring** centered on the photon,
  - a soft **glow** falloff for illumination.
- Removed the path-based beam and residual artifacts.

**Controls**
- Aim: **W/A/S/D**
- Move: **Arrow keys**
- Fire: **Space** (tap/hold)
- Toggle continuous fire: **T**
- λ presets: **1..5** (700/600/500/400/320 nm)
- Fine-tune λ: **-** / **=** (±5 nm)
- Toggle drain: **G**
- Reset: **R**

**Tech**
- Photon entity travels at ~36 cells/sec until it leaves the grid or ages out.
- Visual amplitude per photon: `core + 0.6*ring + glow`, with mild shimmer and lifetime fade.
- Ring radius grows with `waveSpeed = 14 * speedScale(λ)` so short λ looks more energetic.
- Capped to **40 photons** with bbox checks for speed.

**File:** `ascii-photon-v0.5.4-laser-photons.html`
