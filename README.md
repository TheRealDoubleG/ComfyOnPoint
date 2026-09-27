# ComfyOnPoint

**Version 1.12 — Beta**  
**Tested target: WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Author: **TheRealDoubleG**  
Discord: **the.real.double.g**

**Main feature: ComfyOnPoint keeps the tooltip at your mouse cursor instead of letting it jump back to Blizzard's default tooltip position.**

ComfyOnPoint is a lightweight Blizzard-style tooltip addon for World of Warcraft Forever. It preserves the original Blizzard tooltip content — including spell, item and action-bar information — and adds configurable cursor anchoring, profiles, optional unit information, range status, health/resource bars and a live preview.

## Features

- **Tooltip stays at the mouse cursor**, including action-bar spell/item tooltips.
- Four cursor anchor positions: top right, top left, bottom right and bottom left.
- X/Y cursor offset and tooltip window scaling from 50% to 150%.
- Background opacity, text opacity and optional tooltip border.
- Configurable unit-tooltip fade with separate hide delay, fade-in duration and fade-out duration. The default is deliberately quick so crowded player areas do not leave tooltips hanging on screen.
- Keeps Blizzard's original spell/item/action tooltip information.
- Context profiles for world, combat, battlegrounds, dungeons and raids.
- Built-in presets: Minimal, Preferred and Complete.
- Custom named profiles with duplicate/delete support.
- Optional class colors for players when the client exposes the class.
- Optional guild, faction, PvP status and creature type.
- Optional `Faction:` prefix. Disable it to show only `Alliance` / `Horde`.
- Optional `Range:` prefix. Disable it to show only `In Range` / `Out of Range`.
- Range check uses a known class spell and does not invent a result when the client cannot provide one safely.
- Optional health and resource bars above or below the tooltip.
- Minimap button: left-click toggles ComfyOnPoint, right-click opens settings, drag to move when unlocked.
- Saved settings-window position with its own default location, so ComfyOnPoint and ComfyBar no longer open directly on top of each other.
- Settings window uses a dedicated high UI layer and raises when clicked.
- Live tooltip preview in the settings window.
- Automatic German UI on a German client (`deDE`); English on other client locales.
- Info tab shows the **currently running client version, build and interface** and whether the Interface version matches ComfyOnPoint's tested target.
- Optional pet/minion owner display when the client can resolve the owner.
- `/onpoint` and `/op` open the settings.
- `/onpoint debug` prints compatibility information.

## Compatibility monitoring

The repository contains a scheduled GitHub Actions check that looks for a newer WoW Forever build. If a newer build or Interface version is detected, it opens a GitHub issue for compatibility testing.

ComfyOnPoint does **not** automatically claim compatibility with a new Interface version. The `## Interface:` value is only updated after a quick in-game test, so users do not receive an addon that is merely marked current but actually broken.

## Installation

1. Close World of Warcraft Forever.
2. Extract the ZIP archive.
3. Copy the contained `ComfyOnPoint` folder to:

   `World of Warcraft\Interface\AddOns\`

4. The final path must look like:

   `World of Warcraft\Interface\AddOns\ComfyOnPoint\ComfyOnPoint.toc`

5. Start WoW Forever and enable ComfyOnPoint in the AddOns list.

Your settings are stored in `ComfyOnPointDB` and normally survive addon updates. Existing settings from the former `OnPointDB` name are migrated automatically on first launch.

## Beta note

ComfyOnPoint 1.11 is marked as **Beta** while compatibility is being tested against WoW Forever Build 70009. The addon only modifies the user interface. It does not automate gameplay actions and it does not guess values the client does not reliably expose.

---

# ComfyOnPoint – Deutsch

**Version 1.11 — Beta**  
**Getestetes Ziel: WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Autor: **TheRealDoubleG**  
Discord: **the.real.double.g**

**Hauptfunktion: ComfyOnPoint hält den Tooltip am Mauszeiger, statt ihn an die normale Blizzard-Tooltip-Position zurückspringen zu lassen.**

ComfyOnPoint ist ein leichtgewichtiges Tooltip-Addon im Blizzard-Stil für World of Warcraft Forever. Die originalen Blizzard-Tooltip-Inhalte bleiben erhalten – also auch Informationen zu Zaubern, Gegenständen und Aktionsleisten-Skills.

## Highlights

- **Tooltip bleibt am Mauszeiger**, auch bei Zaubern und Items auf der Aktionsleiste.
- Vier Ankerpunkte am Mauszeiger.
- Skalierung, X/Y-Abstand, Hintergrund-/Texttransparenz und Rahmen.
- Profile für Welt, Kampf, Schlachtfeld, Dungeon und Raid.
- Minimal-, Bevorzugt- und Komplett-Voreinstellungen sowie eigene Profile.
- Optionale Gilde, Fraktion, PvP, Kreaturentyp, Pet-Besitzer und Reichweitenstatus.
- Lebens- und Ressourcenbalken.
- Minimap-Button und Live-Vorschau.
- Automatisch Deutsch bei deutschem Client, sonst Englisch.
- Info-Reiter zeigt die echte laufende Client-Version, Build- und Interface-Nummer sowie den Kompatibilitätsstatus.

## Automatische Versionsüberwachung

GitHub prüft regelmäßig, ob ein neuer WoW-Forever-Build erschienen ist. Wird ein neuer Build oder eine andere Interface-Version erkannt, wird automatisch ein GitHub-Issue für den Kompatibilitätstest angelegt.

Die `## Interface:`-Nummer wird bewusst **nicht blind automatisch geändert**. Erst nach einem kurzen Test wird sie aktualisiert, damit ComfyOnPoint nicht nur „nicht veraltet“ aussieht, sondern wirklich funktioniert.

## Installation

ZIP entpacken und den enthaltenen Ordner `ComfyOnPoint` nach

`World of Warcraft\Interface\AddOns\`

kopieren. Danach muss folgende Datei existieren:

`World of Warcraft\Interface\AddOns\ComfyOnPoint\ComfyOnPoint.toc`

WoW anschließend komplett neu starten und ComfyOnPoint in der AddOn-Liste aktivieren.


## Comfy Suite UI standard

ComfyOnPoint follows the shared Comfy Suite menu and Info-tab standard: Blizzard-style movable settings window, top tab navigation, persistent window position, consistent Info layout, Comfy Suite badge, compatibility information, author/Discord/GitHub fields and matching footer styling.


## Rename from OnPoint

Starting with **1.11 Beta**, the addon is named **ComfyOnPoint** to match the Comfy Suite naming scheme.

- New addon folder: `ComfyOnPoint`
- New TOC: `ComfyOnPoint.toc`
- New commands: `/comfyonpoint` and `/cop`
- Legacy commands `/onpoint` and `/op` remain available.
- Existing `OnPointDB` settings are migrated automatically to `ComfyOnPointDB`.
- The legacy global `OnPoint` remains as an alias for compatibility with older integrations.
