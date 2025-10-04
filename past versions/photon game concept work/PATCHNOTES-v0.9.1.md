# Patch Notes — v0.9.1 Detectors + Samples

**Why this makes sense**
- Added **detectors (D)** that count photons by wavelength. They have a passband (here 500–540 nm) like a monochromator window.
- Added **samples (S)** with absorption peaks. Photons can be **absorbed** with probability based on λ; sometimes they **fluoresce** at a longer wavelength (Stokes shift).

**New mission**
- **Calibrate Green Channel:** route the beam through the sample to **DET‑A**, deliver **120 counts** in 500–540 nm, and estimate the **sample peak** (target ~520 nm). Weighted mean of detected λ is used. Completing both marks the mission **calibrated**.

**HUD**
- Goals panel shows delivered counts, your peak estimate with tolerance, and a tiny histogram of detected wavelengths.

**Kept**
- WASD with acceleration, aim-lock (RMB/L), mirrors/walls/absorbers, emissions, battery, RoF control.

This is the first step toward a real spectrophotometer loop: source → wavelength select → sample → detector → analysis.
