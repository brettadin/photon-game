# Patch Notes — v0.9.0 Controls + Obstacles

**Controls feel better instead of cardboard**
- **Acceleration + friction:** no more instant starts/stops. It’s smooth, on purpose.
- **Sprint / precision:** hold **Shift** to sprint, **Ctrl** to slow for pixel-perfect shots.
- **Aim-lock:** toggle with **Right Mouse** or **L**. Move without your cursor yanking the beam.
- **RoF range:** adjustable **6–60/s** with **[ / ]**. Default 26/s. Battery math tweaked to keep it fun.

**Obstacles: actual level geometry**
- **Walls (`#`)**: block you and **reflect** photons axis-aligned.
- **Mirrors (`/` and `\`)**: reflect photons across **y=−x** and **y=x** respectively.
- **Absorbers (`X`)**: eat photons and flash a dim emission.
- Toggle map rendering with **M**. There’s a bordered arena, a dotted wall segment, a side corridor, random mirrors, and corner absorbers.

**Molecules still party**
- They bounce off walls and can be shot like before. Emission pops at the correct bond λ.

**Quality**
- Player visibility beacon remains: neon cross, core block, “YOU,” rotating ^ marker, ping on **F**.
- Wall sliding for movement so you don’t get stuck on corners.
