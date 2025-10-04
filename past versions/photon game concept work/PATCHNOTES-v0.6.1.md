# ASCII Photon — v0.6.1 Molecules + Visibility Safe

**Goal:** stop the “where am I?” problem forever.

### Visibility hardening
- **Always-visible emitter:** draws both text and **rectangle blocks** for the reticle every frame, so even if fonts act up you still see a giant white cross.
- **Boot self‑test:** one-time `getImageData` read to confirm pixels actually change. If not, a **fallback mode** message appears and rectangles take over.
- **Center-on-resize** and clamped spawn so the emitter can’t be off-grid.
- Quick helpers: **C** center, **F** flash ring, **H** aim dots, **D** debug overlay.

### Gameplay kept from v0.6.0
- **Moving molecules** with bond energies; shoot with **Space or Click**. If `E_photon ≥ E_bond`, the bond breaks and the emission pops at `λ = 1240/E_bond`. Otherwise, dim scatter.
- Battery drain scales with frequency; presets and fine tuning intact.

**Files**
- `ascii-photon-v0.6.1-visibility-safe.html`

