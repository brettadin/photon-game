# Launch Blocker Review

This audit lists the issues that previously prevented the Godot project from reaching an interactive state and documents the fixes now applied in the repository. Remaining follow-up items are tracked as recommendations.

## ✅ Assets now live under `res://`
- **Impacted files:** `godot/project.godot`, `godot/scripts/**`, `godot/scenes/**`, `godot/data/**`
- **Resolution:** All gameplay scripts, scenes, and data tables have been moved inside the `godot/` project root so their `res://` paths line up with preload calls. Opening the project no longer produces missing-resource errors for player avatars, abilities, or data-driven systems.

## ✅ Main scene instantiates gameplay scaffolding
- **Impacted file:** `godot/scenes/levels/LevelRoot.tscn`
- **Resolution:** `LevelRoot` now instances the player avatar, a following camera, and the `GameController` singleton so the project boots into a playable shell with character selection available immediately.

## ✅ Default input map covers runtime shortcuts
- **Impacted file:** `godot/scripts/systems/InputBindings.gd`
- **Resolution:** The input autoload seeds bindings for movement, dash, interact, pause, and codex toggling using Godot's built-in `InputMap`, preventing the undefined-action warnings seen in prior editor sessions.

## 🔄 Recommended follow-up
- Convert the placeholder `TileMap` in `LevelRoot` to Godot 4's new layered tilemap workflow so the editor warning disappears and level geometry can be authored visually.
- Flesh out prototype levels under `godot/scenes/levels/` to include collision, hazards, and interactives that match the new player spawn so runs have meaningful encounters.
