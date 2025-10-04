# ASCII Photon — v0.5.3 Laser (Idle Glow Off)

**Goal:** fix the “beam looks like it’s firing when autofire is off.”  
**Change:** the active beam's glow is **disabled while idle** (no rendering when not shooting). Residual pulses still appear only during firing.

**Controls:** same as v0.5.2  
Aim: WASD · Move: Arrow keys · Fire: Space (hold) · Toggle fire: T · λ presets 1..5 · Fine-tune: -/= · Toggle drain: G · Reset: R

**Tech notes**
- The renderer now scales active-beam amplitude by `scale = (firing ? 1 : 0)` before sampling, so idle state contributes nothing to the grid.
- Kept the beam object alive for instant resume, but no draw unless firing.
- You can re-enable idle glow by setting `idleGlowScale` above 0 (e.g., `0.15`) in the source.

**File:** `ascii-photon-v0.5.3-laser.html`
