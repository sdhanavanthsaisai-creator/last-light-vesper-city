# LAST LIGHT: The City That Forgot You & Operation: BLACKOUT

A realistic-cinematic **3D Open-World Mystery & Stealth Game** built for **Roblox Studio (Luau + Rojo)** with a **Playable 3D Web Vertical Slice (Three.js)** so you can playtest, inspect scripts, and develop incrementally in daily 3-hour sessions.

---

## What Is Implemented (Milestone 1 Vertical Slice + Finale BLACKOUT)

1. **Roblox Studio Luau Architecture (`roblox/src/` + `default.project.json`)**:
   - `ReplicatedStorage/Shared/Config.luau` — Game constants, 5 Vesper City districts (`OldQuarter`, `CrownCity`, `BlackwaterDocks`, `Undercity`, `MeridianHeights`), lighting presets, and fair cosmetic GamePass definitions.
   - `ReplicatedStorage/Shared/RemoteDefinitions.luau` — Server-authoritative `RemoteEvent` and `RemoteFunction` registry.
   - `ReplicatedStorage/Shared/MissionDefinitions.luau` — Full objective chains for **Mission 1: Missing Records** (Old Quarter vertical slice) and **Mission 5 Finale: Operation BLACKOUT** (Neon Harbor Power Grid).
   - `ReplicatedStorage/Shared/DialogueDefinitions.luau` — Complete dialogue scripts and branching choices for Noah Reed, Maya Cross, Ghost, Raven, Shade, and Director Marcus Hale (with all 3 endings: *Dawn Over Neon Harbor / The City Remembers*, *The New Director / The New Architect*, and *The Quiet Exit / No Fixed Address*).
   - `ReplicatedStorage/Shared/ItemDefinitions.luau` — Investigation clues, 3 Power Keys, secret collectibles, and the **1989 Vesper Coupe GT** vehicle stats.
   - `ServerScriptService/Services/PlayerDataService.luau` — Server-side `DataStoreService` persistence with retries, Studio fallback, and honest save notifications.
   - `ServerScriptService/Services/MissionService.luau` — Server-validated objective progression, distance checks, city-wide Blackout lighting/neon transition, and co-op/solo ending vote tallying (with Mercy score tie-breaker).
   - `ServerScriptService/Services/VehicleService.luau` — Spawns and drives the 1989 Vesper Coupe GT with headlights, `VehicleSeat`, and Archive/Garage checkpoint detection.
   - `ServerScriptService/Services/StealthGuardService.luau` — Syndicate Grid Guards with `Patrol → Suspicious → Chase → Search → KnockedOut` state machine, raycast light-cone detection (3s standing, 6s crouching, disguise support), and `BillboardGui` suspicion bars.
   - `ServerScriptService/Services/PurchaseService.luau` — Server-validated cosmetic GamePasses and `ProcessReceipt` duplicate-grant protection.
   - `ServerScriptService/Services/WorldBuilderService.luau` — Automatically generates the playable Old Quarter street, Noah's apartment, garage, Municipal Archive Relay, Maya Cross NPC, clues, and Neon Harbor Power Grid in `Workspace` on server boot.
   - `StarterPlayer/StarterPlayerScripts/ClientControllers/` — `DialogueController.luau` (typewriter subtitles, scriptable camera tweening, choice buttons) and `MissionUIController.luau` (Mission Tracker HUD, Investigation Journal, Crouch `[C]`, Disguise `[G]`, Spawn Car `[V]`).

2. **Playable 3D Web Companion & Code Hub (`server.js` + `public/`)**:
   - Play the entire Old Quarter + Operation BLACKOUT vertical slice in 3D right in your browser (`WASD` move/drive, `E` interact/enter car, `C` stealth crouch, `G` maintenance disguise, `V` spawn car, `J` journal).
   - Inspect and copy all 14 Roblox Studio Luau scripts from the built-in **Roblox Studio Luau Scripts** tab.

---

## Quick Start

### 1. Run the 3D Web Vertical Slice & Code Hub
```bash
npm start
# Open http://localhost:3000
```

### 2. Sync into Roblox Studio with Rojo
1. Install [Rojo](https://rojo.space/) (`rojo serve` in this repository root).
2. Open Roblox Studio, connect the Rojo plugin, and press **Play**.
3. `WorldBuilderService.luau` automatically constructs the Milestone 1 street, garage, apartment, car, NPCs, clues, and stealth guards so you can immediately test the full loop before swapping in custom 3D meshes.
