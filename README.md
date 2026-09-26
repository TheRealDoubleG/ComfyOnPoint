# OnPoint

**Version 1.4 — Beta**  
**WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Author: **TheRealDoubleG**  
Discord: **the.real.double.g**
GitHub: **https://github.com/TheRealDoubleG/OnPoint**

OnPoint is a lightweight Blizzard-style tooltip addon for World of Warcraft Forever. It keeps the original Blizzard tooltip content (including spell and item information) and adds cursor positioning, profiles, optional unit information, range status, health/resource bars and a live preview.

## Features
- Optional pet/minion owner display when the client exposes the owner.
- Minimap button positioned on the outside edge of the minimap.
- Tooltip window scaling from 50% to 150%.

- Tooltip follows the mouse cursor.
- Four cursor anchor positions: top right, top left, bottom right, bottom left.
- X/Y cursor offset and tooltip scale.
- Background opacity, text opacity and optional tooltip border.
- Keeps Blizzard's original spell/item/action tooltip information.
- Optional class colors for players when the client exposes the class.
- Optional guild, faction, PvP status and creature type.
- Optional `Faction:` prefix. Disable it to show only `Alliance` / `Horde`.
- Optional `Range:` prefix. Disable it to show only `In Range` / `Out of Range`.
- Range check uses a known class spell and does not invent a result when the client cannot provide one safely.
- Optional health and resource bars above or below the tooltip.
- Context profiles for world, combat, battlegrounds, dungeons and raids.
- Built-in presets: Minimal, Preferred and Complete.
- Custom named profiles with duplicate/delete support.
- Minimap button: left-click toggles OnPoint, right-click opens settings, drag to move when unlocked.
- Live tooltip preview in the settings window.
- Automatic German UI on a German client (`deDE`); English on other client locales.
- `/onpoint` and `/op` open the settings.
- `/onpoint debug` prints basic compatibility information.

## Installation

1. Close World of Warcraft Forever.
2. Extract the ZIP archive.
3. Copy the contained `OnPoint` folder to:

   `World of Warcraft\Interface\AddOns\`

4. The final path must look like:

   `World of Warcraft\Interface\AddOns\OnPoint\OnPoint.toc`

5. Start WoW Forever and enable OnPoint in the AddOns list.

Your settings are stored in `OnPointDB` and normally survive addon updates.

## Beta note

OnPoint 1.4 is marked as **Beta** while compatibility is being tested against WoW Forever Build 70009. The addon only modifies the user interface. It does not automate gameplay actions and it does not guess values the client does not reliably expose.

---

# OnPoint – Deutsch

**Version 1.4 — Beta**  
**WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Autor: **TheRealDoubleG**  
Discord: **the.real.double.g**
GitHub: **https://github.com/TheRealDoubleG/OnPoint**

OnPoint ist ein leichtgewichtiges Tooltip-Addon im Blizzard-Stil für World of Warcraft Forever. Die originalen Blizzard-Tooltip-Inhalte bleiben erhalten – also auch Informationen zu Zaubern, Gegenständen und Aktionsleisten-Skills. OnPoint ergänzt Mauszeiger-Positionierung, Profile, optionale Einheiteninformationen, Reichweitenstatus sowie Lebens- und Ressourcenbalken.

## Installation

ZIP entpacken und den enthaltenen Ordner `OnPoint` nach

`World of Warcraft\Interface\AddOns\`

kopieren. Danach muss folgende Datei existieren:

`World of Warcraft\Interface\AddOns\OnPoint\OnPoint.toc`

WoW anschließend komplett neu starten und OnPoint in der AddOn-Liste aktivieren.
