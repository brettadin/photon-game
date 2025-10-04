# ASCII Photon — v0.6.2 WASD Move + Mouse Aim

**Controls**
- **Move:** WASD (arrows still nudge).
- **Aim:** mouse cursor sets heading.
- **Fire:** Space or Click (tap single, hold stream). **T** toggles autofire.
- **Rescue/UX:** C center, F flash ping, H aim dots, D debug, R reset, G drain, 1..5 presets, -/= fine tune.

**Gameplay**
- Same molecules that drift and bounce. If `E_photon = 1240/λ` ≥ `E_bond`, the bond breaks and emits at `λ_emit = 1240/E_bond`; otherwise dim scatter.

**Tech**
- Removed WASD-aim path; movement is velocity-based with diagonal normalization so speed is consistent.
- Kept visibility hardening from v0.6.1 (block cross + text overlay).

**File**
- `ascii-photon-v0.6.2-wasd-mouse.html`
