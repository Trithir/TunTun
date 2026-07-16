# Tun Tun Roadmap

## Vision

Tun Tun is a simple top-down tower defense game with the roles flipped: the player controls the invading side by choosing troops, spawn points, routes, timing, and pressure, while the computer builds and operates the defense.

The game should feel like progressive infiltration. The player pushes deeper into a defended map, breaking roadblocks and slipping troops past sentries until the castle becomes exposed.

## Current Focus

Build the first playable assault loop.

The immediate goal is not full combat, AI, economy, or procedural generation. The current milestone is a readable top-down playfield with:

- A start area for mobs.
- An end/base area to attack.
- A painted trail and matching `Path2D` route.
- Potential spawn points the player can eventually choose from.
- Roadblocks, sentries, gates, and other defender objectives that can appear when an assault starts.
- Buildable/placement zones where the computer can later place defenses.
- Clear visual separation between road, blocked terrain, and usable terrain.
- A HUD that shows assault progress.
- A retreat option so the player can abandon a bad assault and fall back to an earlier foothold.
- A visible troop queue so assault planning feels concrete before the wave starts.
- A launch phase where the player can release queued troops manually for better timing.

## Progress Log

### 2026-07-07

- Created the Godot project.
- Added Kenney top-down tower defense assets.
- Started planning the flipped tower-defense design.
- Created this roadmap file to track past, present, and future work.
- Created the first editor-ready static map blockout scene at `Scenes/Main.tscn`.
- Added named map anchors for start, end, path points, and build zones.
- Set `Scenes/Main.tscn` as the project's main scene.
- Created the first mob scene at `Scenes/Mob.tscn`.
- Added test movement so one mob follows `Map/Path/PathPoints` when the main scene runs.
- Replaced placeholder map polygons with editor-ready `TileMapLayer` and sprite containers.
- Updated `main.gd` so painted visuals can change without breaking mob path logic.
- Replaced marker-based mob movement with Godot `Path2D` and `PathFollow2D` nodes.

### 2026-07-09

- Confirmed the painted tile map is cosmetic and `Map/Path/MobPath` is the gameplay route.
- Confirmed the mob points forward while following the path.
- Refocused the game around progressive infiltration toward a castle.
- Added the first HUD pass with stage, wave, troops-through progress, castle health, assault status, and a Start Assault button.
- Replaced automatic test spawning with button-driven assault spawning.
- Added the retreat concept: the player can cancel a bad push, regroup, and fall back toward a previous stage.
- Added the first troop queue concept: the player can stack troops visually before launching, remove queued troops, and watch the queue drain as troops spawn.
- Confirmed the start/retreat/progress HUD, troop buttons, and spawn queue are working in the prototype.
- Noted that HUD alignment and layout polish still need a cleanup pass.
- Completed a first HUD alignment pass with grouped status, planning controls, and queue panels.
- Added a top castle-health bar, moved the assault planner into a left dock, renamed Start Assault to Launch, and capped the troop queue by stage.
- Changed launched assaults so queued troop icons are clicked manually to release attackers onto the path.
- Added the first sentry prototype: starter sentries appear on the map, scan for attackers in range, and damage them.
- Added five Stage 1 sentry spawn markers and changed the computer defender setup to randomly choose sentry positions from those markers.
- Extracted the HUD, defender setup, assault queue/spawning, and sentry spawn markers into reusable scenes/scripts.
- Added first combat feedback: sentries animate a brief shot/recoil when firing, and mobs flash/show health only after taking damage.
- Added the first defender budget pass: Stage 1 gives the computer a small budget, and basic sentries spend from it.
- Removed obsolete `StartPoint` and `EndPoint` editor markers; mob start/end now come from the first and last points of `Map/Path/MobPath`.
- Extracted the current map into `Scenes/Stages/Stage1.tscn` so `Scenes/Main.tscn` can stay as the lightweight game shell.
- Added reusable attacker scenes for Grunt, Runner, Brute, and Ranged units, all inheriting from a shared attacker base.
- Added reusable defender tower scenes for Stage 1, Stage 2, and Stage 3 towers, all inheriting from a shared tower base.

## Near-Term Milestones

### Milestone 1: Static Map

- [x] Create a main gameplay scene.
- [x] Add a simple top-down map blockout.
- [x] Mark start, exit, path, and tower-buildable areas.
- [x] Set the main scene in `project.godot`.
- [x] Replace placeholder map visuals with paintable map containers.
- [x] Paint first tile/sprite map in the Godot editor.
- [ ] Confirm final node names and map structure after editor edits.

### Milestone 2: Assault Planning HUD

- [x] Show current stage and wave.
- [x] Show troops-through progress.
- [x] Show castle health.
- [x] Add a Start Assault button.
- [x] Add a Retreat button.
- [x] Show available troop types.
- [x] Let the player choose troop types before launching.
- [x] Show a vertical spawn order legend.
- [x] Let the player remove troops from the queue before launching.
- [x] Clean up HUD alignment and spacing.
- [x] Add a per-stage queue limit that grows as the player advances.
- [x] Extract the HUD into a reusable scene.
- [ ] Let the player choose from visible spawn points.
- [x] After launching, let the player click queued troop icons to release troops manually.
- [ ] Add a troop point pool for building an army.

### Milestone 3: Basic Mob Movement And Assaults

- [x] Spawn one test mob type.
- [x] Move mobs from start to exit along a `Path2D` route.
- [x] Track whether mobs reach the exit.
- [x] Count troops that make it through.
- [x] Let the player retreat from a bad assault.
- [x] Spawn a chosen troop queue instead of a fixed test wave.
- [x] Extract attacker types into reusable scenes.
- [x] End the assault cleanly when all mobs are gone.

### Milestone 4: Progressive Map Reveal

- [x] Create a separate scene for Stage 1.
- Define stage sections of the map.
- Start with only the first section active/important.
- When enough troops make it through, advance the stage.
- When the player retreats, fall back to the previous stage or current foothold.
- Reveal or shift to new paths, spawn points, roadblocks, sentries, or gates.
- Keep old stage progress readable so the player feels the push toward the castle.

### Milestone 5: Defender Setup

- [x] Add simple sentry placeholders to the map.
- [x] Add Stage 1 sentry spawn points.
- [x] Let sentries detect attackers in range.
- [x] Let sentries damage attackers.
- [x] Extract defender setup into a reusable manager scene.
- [x] Extract sentry spawn points into reusable scene instances.
- [x] Give the computer a simple budget.
- [x] Let it place basic sentries on valid marker positions.
- [x] Randomize defender placement from allowed Stage 1 sentry positions.
- [x] Extract staged tower types into reusable scenes.
- Let it place roadblocks or other tower types on valid positions.
- Start with deterministic placement before adding smarter behavior.

### Milestone 6: Combat Loop

- [x] Defender sentries/towers target mobs in range.
- [x] Mobs have health and speed.
- [x] Show basic sentry firing feedback.
- [x] Show basic mob damage/health feedback.
- Roadblocks can be damaged or bypassed.
- Player wins by cracking the castle or getting enough troops through; computer wins by stopping the assault.

## Design Notes

- The player should feel like they are outsmarting a defender, not just spawning units on cooldown.
- Early decisions can be simple: choose troop mix, choose spawn point, launch assault.
- The spawn order should be visible before launch. Troop icons should drain from the queue as they enter the map.
- Manual troop release after launch should become a near-term strategy feature: the player plans the army first, launches the assault, then clicks troop icons from the queue to send attackers at chosen timings.
- The computer defense should be understandable. If it places a tower, the player should be able to tell why that spot matters.
- Avoid complex pathfinding until the basic loop is fun.
- Painted tiles are visual. Gameplay paths should use explicit `Path2D` nodes.
- The mob route's first and last `Path2D` points define the current gameplay start and end.
- Roadblocks, sentries, gates, and spawn points should be separate gameplay nodes, not inferred from tile art yet.
- Retreat should be tactical, not pure failure. It should clear active attackers, preserve enough information for the player to learn from the failed push, and eventually move the view back to the previous foothold.
- Stronger troops should eventually cost more from an army point pool, so the player chooses between quantity, speed, and durability.

## Open Questions

- Should the player draw paths freely, choose from preset routes, or place path tiles?
- Does the computer build before the wave, during the wave, or both?
- Is the player primarily trying to damage the castle, leak a number of troops through, or both?
- Should maps be handcrafted levels or generated puzzles?
- Does each stage reveal by camera movement, map panning, unlocking hidden tiles, or loading a new section?
- Should defender placements be random per stage, random per full level, or selected from personality templates?
- When retreating, should defender placements reroll, stay fixed, or partially reset?
- How large should the army point pool be, and should unused points carry between stages?

## Later Ideas

- Multiple mob types: fast, armored, swarm, decoy, tower-disabler.
- Army point pool for drafting stronger or larger troop groups.
- Computer defender personalities: cheap spammer, sniper builder, balanced planner.
- Fog-of-war or limited preview of computer tower choices.
- Round-based drafting: player drafts mobs, computer drafts towers.
- Upgrades for both sides between rounds.
