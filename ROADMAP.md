# Tun Tun Roadmap

## Vision

Tun Tun is a simple top-down tower defense game with the roles flipped: the player controls the invading side by choosing mobs, routes, timing, and pressure, while the computer builds and operates the tower defense.

The game should start small and playable, then grow through clear experiments.

## Current Focus

Build the first map prototype.

The immediate goal is not combat, AI, economy, or waves. The first milestone is a readable top-down playfield with:

- A start area for mobs.
- An end/base area to attack.
- A path or path-building space.
- Buildable zones where the computer can later place towers.
- Clear visual separation between road, blocked terrain, and usable terrain.

## Progress Log

### 2026-07-07

- Created the Godot project.
- Added Kenney top-down tower defense assets.
- Started planning the flipped tower-defense design.
- Created this roadmap file to track past, present, and future work.
- Created the first editor-ready static map blockout scene at `Scenes/Main.tscn`.
- Added named map anchors for start, end, path points, and build zones.
- Set `Scenes/Main.tscn` as the project's main scene.

## Near-Term Milestones

### Milestone 1: Static Map

- [x] Create a main gameplay scene.
- [x] Add a simple top-down map blockout.
- [x] Mark start, exit, path, and tower-buildable areas.
- [x] Set the main scene in `project.godot`.
- [ ] Replace or refine placeholder map visuals in the Godot editor.
- [ ] Confirm final node names and map structure after editor edits.

### Milestone 2: Player Route Planning

- Let the player inspect or choose a mob route.
- Keep route rules simple at first, likely a fixed path or a few selectable lanes.
- Show the chosen route clearly before any mobs spawn.

### Milestone 3: Basic Mob Movement

- Spawn one mob type.
- Move mobs from start to exit along the selected path.
- Track whether mobs reach the exit.

### Milestone 4: Computer Tower Setup

- Give the computer a simple budget.
- Let it place basic towers on valid buildable tiles.
- Start with deterministic placement before adding smarter behavior.

### Milestone 5: Combat Loop

- Towers target mobs in range.
- Mobs have health and speed.
- Player wins by getting enough mobs through; computer wins by stopping them.

## Design Notes

- The player should feel like they are outsmarting a defender, not just spawning units on cooldown.
- Early decisions can be simple: choose path, choose mob mix, launch wave.
- The computer defense should be understandable. If it places a tower, the player should be able to tell why that spot matters.
- Avoid complex pathfinding until the basic loop is fun.

## Open Questions

- Should the player draw paths freely, choose from preset routes, or place path tiles?
- Does the computer build before the wave, during the wave, or both?
- Is the player trying to destroy a base, leak a number of mobs through, or earn score across multiple rounds?
- Should maps be handcrafted levels or generated puzzles?

## Later Ideas

- Multiple mob types: fast, armored, swarm, decoy, tower-disabler.
- Computer defender personalities: cheap spammer, sniper builder, balanced planner.
- Fog-of-war or limited preview of computer tower choices.
- Round-based drafting: player drafts mobs, computer drafts towers.
- Upgrades for both sides between rounds.
