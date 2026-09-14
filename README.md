<div align="center">

  <img src="https://i.imgur.com/XyhEFsY.gif" alt="WASOR v3.7 Banner" width="480" style="border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.6);" />

  # ⚡ WASOR v3.7
  ### *We Are Skidding On Roblox*

  [![Documentation](https://img.shields.io/badge/Documentation-Live_on_Vercel-34d399?style=for-the-badge&logo=vercel&logoColor=white)](https://wasordocumentation.vercel.app/#intro)
  [![Version](https://img.shields.io/badge/Version-3.7_Production-7c3aed?style=for-the-badge)](https://wasordocumentation.vercel.app/)
  [![Roblox](https://img.shields.io/badge/Platform-Roblox_Lua-00a2ff?style=for-the-badge&logo=roblox&logoColor=white)](https://wasordocumentation.vercel.app/)
  [![Languages](https://img.shields.io/badge/i18n-10_Languages-f59e0b?style=for-the-badge)](https://wasordocumentation.vercel.app/)
  [![Modules](https://img.shields.io/badge/Modules-98_Active-10b981?style=for-the-badge)](https://wasordocumentation.vercel.app/)

  **A high-performance, modular Roblox Lua client-side utility framework featuring 98 distinct modules across Combat, Movement, Render, Player, World, and Utility engines.**

  [🌐 **Explore Official Live Documentation**](https://wasordocumentation.vercel.app/) • [📖 **API Reference**](https://wasordocumentation.vercel.app/#aimbot) • [⚡ **Quickstart**](#-quickstart--execution) • [🛠️ **Features**](#-features--module-breakdown)

</div>

---

## 📖 Official Interactive Documentation

The complete reference documentation is deployed and accessible at:
### 👉 [https://wasordocumentation.vercel.app/](https://wasordocumentation.vercel.app/#intro)

* **Interactive API Reference**: Comprehensive specifications for all 98 modules with live parameter descriptions and reproducible Lua snippets.
* **10-Language Instant Localization**: Switch seamlessly between **English**, **Español**, **Português**, **简体中文**, **한국어**, **日本語**, **Русский**, **Deutsch**, **Français**, and **Italiano**.
* **Global Search (Ctrl + K)**: High-speed fuzzy search across all functions, parameters, aliases, and localized keywords.
* **Status Badges**: Real-time status indicators across all engines (`Working`, `Defunct`, `Patched`, `Broken`).

---

## ⚡ Quickstart & Execution

To execute the production build of WASOR v3.7 directly in any modern executor:

```lua
if identifyexecutor then
    game:GetService("GuiService"):SetGameplayPausedNotificationEnabled(false)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/VenezzaX/WASORCLASSIC/refs/heads/main/github_loader.lua", true))()
end
```

---

## 🛠️ Features & Module Breakdown

WASOR is organized into **6 core modular divisions** containing **98 specialized routines**:

### ⚔️ Combat Operations (12 Modules)
* **Aimbot** — Smooth camera target tracking with configurable FOV circles, raycast line-of-sight verification, and bone selection (`Head`, `Torso`, `Random`).
* **Aimlock** — Direct camera lock-on with instant CFrame snapping without smoothing latency.
* **Silent Aim** — Hooks raycasts and mouse target queries to redirect weapon trajectories without moving the viewport.
* **AutoPlayBot** — Autonomous pathfinding AI with obstacle navigation and auto-engagement (custom-tailored for Arsenal).
* **AutoClicker** — Virtual input loop emulating mouse clicks with customizable CPS rates (1–50+ clicks/sec).
* **Triggerbot** — Microsecond reaction loop firing weapons the instant an enemy enters the crosshair.
* **Kill Aura** — Spatial proximity damage generator applying weapon hitboxes across surrounding entities.
* **Fling Player & Fling All** — High-torque angular velocity transfer catapulting targets out of bounds.
* **Walkfling** — Gyro-stabilized physical momentum launcher triggering on body contact.
* **God Mode & No Recoil** — Client-side death suppression and camera recoil spring dampening.

### 👤 Player & Identity (13 Modules)
* **Anti-AFK** — Intercepts `LocalPlayer.Idled` to bypass Roblox's 20-minute idle disconnect barrier.
* **Auto-Rejoin** — Watchdog monitoring CoreGui prompt errors (268, 277) to automatically reconnect.
* **Click Teleport** — Instantly warps the character's CFrame to the cursor's world position on click.
* **Click Delete** — Remove local map obstructions, walls, and collision meshes with `Ctrl + Click`.
* **Spectate & FreeCam** — Smooth scriptable 6-DOF camera mode with velocity dampening to inspect other players without moving your avatar.
* **Force Shift Lock** — Bypasses experience developer restrictions to enable mouse-lock anywhere.
* **Give BTools** — Instantiates client-side HopperBins (Move, Delete, Undo, Clone) in the local Backpack.
* **Nametag Customizer & UI Spoof** — Client-side overhead billboard styling with neon gradients, plus UI text masking.
* **Instant Respawn & Character Reset** — Clean state reset and rapid respawn triggers.
* **Unlock Max Zoom** — Eliminates camera distance restrictions (`CameraMaxZoomDistance = math.huge`).

### 🏃 Advanced Movement (23 Modules)
* **Auto Bunnyhop** — Replicates CS 1.6 GoldSrc air acceleration, maintaining and compounding speed upon ground contact.
* **Air Swim & Swim in Air** — Forces native swimming physics states in mid-air for free 3D traversal.
* **Air Walk Platform** — Spawns an invisible dynamic platform beneath the avatar with elevation hotkeys.
* **Wall Run & Climb** — Scale sheer vertical cliffs and sprint horizontally across wall surfaces.
* **Fly & Fly Bypass** — Smooth free-flight system with discretized physics pulses to evade strict anticheats.
* **Ghost Mode** — Noclip gliding mode with transparent avatar rendering and planar movement.
* **Spider Climb** — Converts forward running velocity into vertical climbing traction.
* **Infinite Jump & Jump Force** — Unlimited consecutive mid-air jumps with configurable jump power multipliers.
* **Water Walk (Jesus Mode)** — Generates dynamic surface colliders over terrain water (optimized for Isle).
* **Noclip** — Disables `CanCollide` across all character limbs during `RunService.Stepped`.
* **Player Spin & Spinbot** — High-frequency yaw axis rotation confusing enemy aim tracking.
* **Ultra Instinct** — Autonomous proximity scanner triggering evasive micro-teleports against incoming threats.
* **Gravity, Anti-Sit & Anti-Anchor** — Total gravitational control, seat trap prevention, and local anchor overrides.

### 👁️ Visuals, ESP & HUD (24 Modules)
* **Comprehensive ESP Suite** — 2D Bounding Boxes, Tracers, Player Names, Distance, and Health bars via Drawing API.
* **Chams & Wallhacks** — Native `Highlight` instances with customizable fill, outline, and `AlwaysOnTop` depth modes.
* **Line of Sight Lasers** — Projects 3D laser vectors showing the exact gaze and aiming angles of opponents.
* **Skeleton ESP** — Real-time kinematic bone articulation lines for R6 and R15 avatar rigs.
* **Radar Minimap HUD** — Orthographic compass-oriented radar display displaying nearby entities.
* **Minecraft PE Paper Doll** — Authentic Bedrock/PE style HUD doll mirroring live walking, jumping, and swimming animations.
* **ESP Preview Studio** — Real-time 3D ViewportFrame for calibrating styles, colors, and offsets before deployment.
* **Map X-Ray & Clear Vision** — Structural transparency overrides combined with total atmospheric fog removal.
* **Fullbright & Time Cycle** — Permanent daylight illumination with custom ambient color shift controls.
* **Lag Reducer & 3D Rendering Toggle** — GPU saving modes reducing texture budgets and suspending 3D passes for background farm efficiency.

### 🌍 World Manipulation (13 Modules)
* **Anti-Fling Guardian** — Cancels foreign angular velocities and neutralizes violent player collisions.
* **Anti-Void Net** — Safety net repositioning the avatar to safe coordinates prior to falling below the kill boundary.
* **Proximity Prompt Suite** — Auto-trigger prompts, instant interaction (`HoldDuration = 0`), and global bulk activation.
* **Fire Touchinterests** — Simulates physical contact with badges, checkpoints, and rewards without walking to them.
* **Fire ClickDetectors** — Triggers buttons, levers, and switches across the entire map simultaneously.
* **Destroy Killbricks & Seats** — Client-side purges of lethal lava bricks, lasers, and unwanted seats.
* **Tool Magnet** — Attracts and claims all loose tools and items on the map straight to your character.
* **Waypoint Warp** — Coordinate memory system for saving and recalling precise spatial locations.

### ⚙️ Utilities & Diagnostics (12 Modules)
* **Network Chat Hub** — Inter-server global chat network connecting WASOR users across different games.
* **Chat Logger** — Archives all local, team, and whispered server communications into an exportable buffer.
* **Console Viewer** — In-game dark terminal displaying live `LogService` prints, warnings, and errors.
* **External ScriptHub** — Instant one-click execution catalog for popular community tooling (Dark Dex, RemoteSpy, IY).
* **UNC Compliance Audits** — Rigorous automated benchmark testing executor environment API compatibility.
* **Place Archiver (`saveinstance`)** — Exports the current map hierarchy, geometry, and local scripts into a `.rbxl` file.
* **Favorites & Server Manager** — Server hopping, fast rejoin via `JobId`, and bookmarking system.
* **Keybind Dispatcher & Module Masking** — High-priority input event mapping and customizable button visibility modes.

---

## 📂 Project Architecture

```
WASOR/
├── Core/
│   ├── Services.lua         # Centralized Roblox service caching
│   ├── State.lua            # Reactive configuration & runtime flags
│   ├── Utils.lua            # Mathematical solvers, raycasting & math
│   ├── Config.lua           # Persistent JSON storage handler
│   ├── Logger.lua           # Chat & system output interceptor
│   ├── Cleanup.lua          # Garbage collection & Drawing disposal
│   ├── UI.lua               # Custom dark glassmorphic interface engine
│   └── Runtime.lua          # Heartbeat, Stepped & RenderStepped loops
├── Modules/                 # Modular functional domains
│   ├── Combat/              # Targeting, weapon mechanics & damage
│   ├── Player/              # Character state & identity spoofing
│   ├── Movement/            # Kinematics, flight & physics overrides
│   ├── Render/              # Drawing API ESP & visual enhancements
│   ├── World/               # Environment triggers & world interaction
│   └── Misc/                # Network tools, console & diagnostics
├── docs/                    # Official Vercel documentation site
│   ├── index.html           # Full 10-language documentation app
│   └── assets/              # High-speed animated visual assets
├── init.lua                 # Primary initialization gateway
├── dev_loader.lua           # Local workspace testing loader
├── github_loader.lua        # Production remote GitHub loader
└── vercel.json              # Vercel deployment & routing config
```

---

## ⚡ Local Development Setup

To test and modify WASOR source code locally:

1. Clone or place the `WASOR` directory directly inside your executor's `workspace` folder:
   ```
   <Executor>/workspace/WASOR/
   ```
2. Execute the local development loader:
   ```lua
   loadstring(readfile("WASOR/dev_loader.lua"))()
   ```

---

## 🌐 Community & Links

* 🔗 **Live Documentation**: [https://wasordocumentation.vercel.app/](https://wasordocumentation.vercel.app/#intro)
* 🐙 **GitHub Repository**: [https://github.com/VenezzaX/WASORCLASSIC](https://github.com/VenezzaX/WASORCLASSIC)

---

<div align="center">
  <sub>WASOR v3.7 is developed for software interoperability testing and educational security research.</sub>
</div>
