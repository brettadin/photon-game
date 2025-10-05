# Code Review Findings

This document summarizes blocking issues uncovered while reviewing the current Godot project layout and runtime scripts. Each section lists the impacted files and concrete steps required to resolve the problem so the game can boot into a playable state.

## 1. Input bindings autoload never populated actions
- **Impacted file:** `godot/scripts/systems/InputBindings.gd`
- **What happens:** The autoload previously attempted to fetch Godot's `InputMap` via `Engine.get_singleton("InputMap")`, which returns `null` in Godot 4. As a result `_ready()` aborted and no default controls were registered, matching the editor warnings you captured.
- **Fix applied:** The autoload now calls the built-in `InputMap` singleton directly, registers the default action set on startup, and uses explicit `JOY_BUTTON_A/JOY_BUTTON_B` constants so controller prompts map correctly.

## 2. Gameplay content lives outside the `res://` project root
- **Impacted files:**
  - `scripts/**`, `scenes/**`, and `data/**` at the repository root
  - `godot/project.godot`
  - `godot/scenes/levels/LevelRoot.tscn`
  - `scripts/game/game_controller.gd` and every script that preloads `res://scripts/...`
- **What happens:** The Godot project only includes `godot/scenes` and `godot/scripts/systems`. All other scenes, scripts, and data referenced via `preload("res://…")` remain outside the project directory, so Godot cannot resolve them when `LevelRoot.tscn` loads. This prevents the player, HUD, abilities, and hazards from instantiating and leaves the viewport blank.
- **Proposed fix:** Move the repository's `scripts/`, `scenes/`, and `data/` folders into `godot/` so their paths match the expected `res://` locations. After moving, open the project in Godot to let it repair any resource references.

## 3. Root level scene lacks gameplay instances
- **Impacted file:** `godot/scenes/levels/LevelRoot.tscn`
- **What happens:** The main scene configured in `project.godot` is just a tilemap shell with spawn markers. Even after the asset paths are fixed, there is no `GameController`, player avatar, camera, or HUD instanced in the tree, so the screen remains empty.
- **Proposed fix:** Instance the gameplay scaffolding into `LevelRoot.tscn` (or create a new main scene) that adds `GameController` with its `player_path` bound, spawns the player avatar, attaches a camera, and drops in a prototype level so the project has visible content when run.

## 4. Data-driven systems cannot locate their resources
- **Impacted files:** `scripts/abilities/**`, `scripts/classes/**`, `data/boons/**`, `data/classes/**`, and any other resource loaded via `load("res://...")`.
- **What happens:** Similar to the scene/scripts layout issue, every data-driven subsystem (ability catalog, class definitions, codex database, boon manager) expects JSON or `.tres` assets under `res://data`. Because those directories currently sit outside `godot/`, attempting to start a run would trigger load failures even if the scenes were instanced correctly.
- **Proposed fix:** After moving the `data/` folder into `godot/`, verify each loader path and run the project to confirm the data tables deserialize without errors.

Addressing items 2–4 will align the filesystem with the resource paths hard-coded throughout the scripts, remove the missing-file warnings, and allow `GameController` to drive an actual run once the main scene is populated.
