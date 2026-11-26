# CompassToggle

An [Icarus](https://store.steampowered.com/app/1149460/ICARUS/) UE4SS Lua mod by **CUTLINGTON/CLAUDE AI**.

Turn beacon markers on and off. One key per marker type hides or shows that type on **both the compass bar at the top of the screen and the big map** at the same time.

It is visual only. It changes what is drawn on your screen, not any game values, buffs or save data, and it does nothing until you press a key. Nothing is saved, so every launch starts with all markers shown.

**Last tested:** 25 Nov 2026 with Icarus and UE4SS.

## Requirements

- Icarus (PC)
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases) installed for Icarus and confirmed working

## Install

1. Download this repository (Code, then Download ZIP) or the zip from the Releases page.
2. Copy the `CompassToggle` folder into your UE4SS `Mods` folder:

   ```
   Icarus\Binaries\Win64\ue4ss\Mods\CompassToggle
   ```

   Older UE4SS builds use `Icarus\Binaries\Win64\Mods\CompassToggle` instead.

3. Check it looks like this:

   ```
   Mods\CompassToggle\enabled.txt
   Mods\CompassToggle\Scripts\main.lua
   ```

4. Start the game. Mods with an `enabled.txt` start automatically, so you don't need to edit `mods.txt`.

To uninstall, delete the `CompassToggle` folder.

## Controls

| Key | Action |
|---|---|
| **F8** | Hide / show the regular portable beacon markers |
| **F9** | Hide / show the prototype portable beacon markers |
| **F7** | Rescan (only does anything while a marker type is hidden) |
| **Esc** | Shows every marker again while the pause menu is open, and hides them again when you close it with Esc |
| **F11** | Manual restore, if you closed the pause menu without pressing Esc (for example by clicking Resume) |

F9 uses the game's "dynamic mission beacon" type. In testing this matched the prototype portable beacons, but it may also affect other markers of the same type.

The keys are set at the top of `main.lua` if you need to change them. F10 is already used by the UE4SS console.

## How the Esc key behaves

Hiding markers means the mod keeps working in the background. While testing, the game crashed a few times around loading screens when markers were hidden. To avoid this, the mod shows everything again as soon as you press Esc, so nothing is running if you quit or go back to the character select screen.

- **First Esc press:** every marker is shown, the mod goes idle, and it remembers what you had hidden.
- **Next Esc press (closing the menu):** what you had hidden is hidden again.
- **Closing with the Resume button instead:** the mod doesn't know the menu closed. Press **F11** to hide your markers again.
- **Pressing F8 or F9 yourself** cancels any pending restore.
- **Esc also closes the map and inventory,** so markers will reappear and then hide again as you open and close those too.
- **If nothing is hidden,** Esc does nothing.

Good habit: always leave the world through the pause menu (Esc first). Leaving some other way, such as Alt+F4 or crashing out, is not covered.

## Known quirks

- A beacon you build while its type is hidden may keep its map marker until you press F7, or toggle that type off and on.
- The first press of a key does a short scan of the game's objects, so you may notice a tiny hitch. While something is hidden, the mod re-applies it about once a second without scanning.
- If you load into a different world, press F8 or F9 again so it can find the new icons.
- Markers are hidden by making them fully transparent. The game's own show/hide logic is not touched, but a hidden marker's hover tooltip may still appear on the map.

## Settings

At the top of `Scripts/main.lua`:

| Setting | What it does |
|---|---|
| `TICK_MS` | How often hidden markers are re-applied, in milliseconds. Default `1000`. Raise it (for example `2000`) for even less work. A hidden marker may then reappear for up to that long. |
| `categories` | One line per marker type: the key, the game's class name for the object, and a label. To add another type, copy a line and change the key and class name, for example `BP_Portable_Beacon_C` or `BP_Dynamic_Mission_Beacon_C`. |

## Compatibility

- Tested in single player / offline only. Multiplayer is untested. Follow the rules of any server you play on.
- The mod relies on Icarus's internal names (for example `UMG_IcarusCompassIcon_C` and `BP_Dynamic_Mission_Beacon_C`). A game update that renames or changes these can break it.
- UE4SS itself adds some overhead. If you only use mods and not the debug tools, set `GuiConsoleEnabled = 0` in `UE4SS-settings.ini`.
- It does not need my other mod, [BeaconZoneRing](https://github.com/[YOUR-GITHUB-NAME]/Icarus-BeaconZoneRing), and neither needs the other. If you install both, they both use Esc and both respond to it, which is fine.

## Troubleshooting

- **Nothing happens:** check `UE4SS.log` (next to `UE4SS.dll`) for lines starting `[CompassToggle]`. A toggle press prints `HIDDEN` or `shown`. If there are no lines at all, the mod isn't loading, so check the folder layout.
- **The game won't start:** rename `enabled.txt` to `enabled.txt.off` to disable the mod, and check that UE4SS works without it.
- **A crash:** please open an issue with your `UE4SS.log` and say whether any markers were hidden at the time. Remove the `LoginId` and `EpicAccountId` lines from any crash report before posting it.

## Changelog

### v1.0
First release. F8 and F9 toggles for compass and map, F7 rescan, Esc and F11 pause-menu safety routine.

## Credits and license

Made by **CUTLINGTON/CLAUDE AI**. Built on [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS).

Released under the MIT License (see `LICENSE`). Not affiliated with or endorsed by RocketWerkz, the makers of Icarus. Use at your own risk.
