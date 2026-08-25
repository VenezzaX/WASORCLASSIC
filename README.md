# WASOR
WeAreSkiddingOnRoblox is a utility full with various functions.
If you are developing or debugging individual modules, you can use the dynamic loader:

```lua
if identifyexecutor then
game:GetService("GuiService"):SetGameplayPausedNotificationEnabled(false)
loadstring(game:HttpGet(('https://raw.githubusercontent.com/MizunoSync/WASOR/refs/heads/main/github_loader.lua'),true))()
end
```

---

## 🛠️ Feature Cheat Sheet

WASOR comes packed with a shit ton of options split into 6 major panels: (Some may be broken but anyways, most of it works fine.)

### ⚔️ Combat
* **Aimbot & Aimlock** — Configurable lock-on with FOV circles, wall-checks, and target part selectors (dome, torso, or random) for when you literally too dumb to aim.
* **AutoPlayBot** - Pretty self explanatory.
* **Silent Aim** — Hooks standard mouse `__index` (`Mouse.Hit` / `Mouse.Target`). Warning: currently it is not working as metatable raycast namecalls are disabled to prevent camera scripts from glitching.
* **Kill Aura** — Uses a tool that does damage to kill any opponent.
* **Fling Player & Fling All** — Send mfs straight to orbit.
* **Auto-Clicker & Triggerbot** — Triggerbot shoots automatically the millisecond someone crosses your crosshair, while auto-clicker uses basic click loops (`mouse1press` / `mouse1release`).
* **God Mode & No Recoil** — Attempts to make the user immortal. No Recoil is currently non-functional.

### 👤 Player Stuff
* **Nametag Customizer & Spoof** — Change display name in ui which is pretty unstable, customizable client tags.
* **Click Teleport & Click Delete** — Hold Ctrl to blink to mouse, or Alt to delete whatever annoyances are in your way.
* **Instant Respawn & Auto Rejoin** — Instant respawn your plr. / Auto Rejoins games in case of disconnect.
* **Spectate & Freecam** — Ghost around the map or spy on other players with HUD stats.
* **BTools & Anti AFK** — F3X building tools to delete walls, and Anti-AFK so you can go touch grass without getting kicked.

### 🏃 Movement
* **Speed & Jump Hacks** — Speed/jump modifier pretty self explanatory.
* **Fly & Fly Bypass** — Fly modules for ur needs.
* **Bunnyhop & Auto-Walk** — Bunny hop is fully fixed using CS 1.6 GoldSrc air acceleration, speed building, auto-strafe, and slip-sliding physics. Auto-walk pathfinds to the cursor location only when MouseButton1 (M1) is clicked.
* **Noclip, Air Walk & Water Walk** — Walk through walls, stand in the air, or walk on water. (Pretty self explanatory)
* **Wall Run & Climb** — Scale and slide on walls with smooth velocity changes and automatic ledge jumping/vaulting over the top.
* **Gravity, Anti-Sit & Anti-Anchor** — Override gravity, stop seats from trapping you, and ignore anchor blocks.(Pretty self explanatory)
* **Ultra Instinct** — Draws a customizable neon-red circle under the player's feet, performing automated teleports to dodge opponents when they enter the radius.

### 👁️ Visuals (ESP & Wallhacks)
* **ESP Engine** — Full 2D boxes, skeleton lines, health bars, player names, and tracers. You see everything.
* **Line of Sight ESP** — Renders aiming lines showing where opponents are aiming, with team check, friend check, and length filters.
* **Chams** — Highlight character models through walls so nobody can hide.
* **Map X-Ray & Clear Vision** — Remove annoying fog and make walls see-through.
* **Lag Reducer & FPS Cap** — Boost your frames on potato PCs by disabling shadows and particles.
* **Fullbright & Time Cycle** — Locked daylight or cycle time of day super fast.

### 🌍 World (Map Abuse)
* **Fire touchinterests** — Relocated from Combat. Fires nearby touch interests as you move.
* **Proximity Prompt Hacks** — Auto-trigger prompts, instant interact, and fire them all from across the map.
* **Anti-Void Net** — Auto-saves you if you fall into the void, teleporting you back to safety.
* **Tool Magnet(Local)** — Suck every dropped tool in the map straight to your character.(Client)
* **Destroy Killbricks & Seats** — Vaporize laser walls and seats instantly.(Client)

### ⚙️ Other Cool Stuff
* **Chat Logger & Console Log Viewer** — Keep tabs on everything said in chat and view internal execution outputs.(can be found in your exploit workspace)
* **Favorites Manager** — Bookmark your favorite games.
* **UNC compliance Audits** — Test if your executor is actually good or garbage.
* **Network Chat Hub** **—** Global chat network with other hub users using this same script.
* **Rainbow Theme & Refresh UI** — Cycle through RGB colors dynamically and refresh the user interface on-the-fly to clear visual bugs.

---

## 📂 Project Directory

```
WASOR/
├── Core/
│   ├── Services.lua     # Grab Roblox services
│   ├── State.lua        # Shared config & current toggles
│   ├── Utils.lua        # Heavy lifting (Freecam, Aimbot, etc.)
│   ├── Config.lua       # Auto-saving JSON files
│   ├── Logger.lua       # Chat & Console logger hookups
│   ├── Cleanup.lua      # GC & ESP connection disposal
│   ├── UI.lua           # WeAreSkidding UI builder core
│   └── Runtime.lua      # Heartbeat/Stepped main render loops
├── Modules/             # Dynamic feature scripts
│   ├── Combat/
│   ├── Player/
│   ├── Movement/
│   ├── Render/
│   ├── World/
│   └── Misc/
├── init.lua             # Entry-point loader
├── dev_loader.lua       # Local workspace testing loader
├── github_loader.lua    # Production raw GitHub loader
└── README.md            # You are reading this
```

---

## ⚡ Cooking Locally (Dev Setup)

If you want to edit files and test this codebase locally:
1. Throw the `WASOR` folder inside your executor's `workspace` folder.
2. Run this block in your executor to load directly from your PC:
   ```lua
   loadstring(readfile("WASOR/dev_loader.lua"))()
   ```
