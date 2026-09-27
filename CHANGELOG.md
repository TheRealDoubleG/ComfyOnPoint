# OnPoint Changelog

## 1.10 Beta - 27.09.2026
- Adopted the shared Comfy Suite UI standard.
- Added the Comfy Suite badge to the Info tab.
- Added Comfy Suite metadata to the TOC so current and future suite tools can identify OnPoint as part of the family.
- Standardized the Info-tab structure and family styling with ComfyBar, ComfyCC and ComfyHub.


## 1.9 Beta - 27.09.2026
- Renamed the main enable setting from "Addon enabled" to "Enable OnPoint" for consistency with ComfyBar.
- German client label is now "OnPoint aktivieren".


## 1.8 Beta - 27.09.2026
- Fixed overlapping copyright/thanks text at the bottom of the Info tab.
- Added configurable fading for unit/player mouseover tooltips.
- Added separate settings for hide delay after leaving a target, fade-in duration and fade-out duration.
- Default unit tooltip timing is now quick: 0.10 s hold, 0.08 s fade-in and 0.12 s fade-out.
- Item and spell tooltips are excluded from the unit fade logic so normal action/item tooltip behavior is preserved.


## 1.7 Beta - 27.09.2026
- Added persistent OnPoint settings-window positioning.
- Gave OnPoint a separate right-offset default settings-window location so it no longer opens directly on top of ComfyBar.
- Moved the settings window to HIGH strata / level 20, enabled top-level behavior and raise-on-click.
- Kept OnPoint's tooltip health/resource bars on the TOOLTIP layer by design, separate from ComfyBar's normal MEDIUM-layer bars.


## 1.6 Beta - 27.09.2026
- Fixed the minimap tracking-border anchor so the gold ring now sits correctly around the OnPoint icon instead of appearing detached.

## 1.5 Beta - 26.09.2026
- Added live client version, build and Interface detection to the Info tab.
- Added a clear compatibility status comparing the running client Interface with OnPoint's tested Interface.
- Added scheduled GitHub monitoring for new WoW Forever builds; a compatibility issue is created when a newer build or Interface is detected.
- Reworked the GitHub README so the original/main feature — keeping the tooltip at the mouse cursor — is listed first.
- Kept Interface updates test-gated instead of blindly marking untested game versions as compatible.

## 1.4 Beta - 26.09.2026
- Corrected the public author name to `TheRealDoubleG` everywhere.
- Added the official GitHub project URL to addon metadata, the Info tab and README.
- Prepared the source tree for the public GitHub repository.

## 1.3 Beta - 26.09.2026
- Added optional pet/minion owner display when the Forever client can resolve the owner.
- Added pet preview to the live preview page.
- Reworked the minimap button position so the button sits outside the minimap edge instead of covering the map.
- Centered the minimap button border around the button.
- Kept and clarified the tooltip window scale option (50-150%).
- Existing custom profiles are automatically extended with the new pet-owner option.

## 1.2 — Beta — 26.09.2026

### Added
- German/English localization based on the WoW client language.
- Four configurable cursor anchor positions: top right, top left, bottom right and bottom left.
- Tooltip scale setting.
- Separate profile options for showing/hiding the `Faction:` prefix.
- Separate profile options for showing/hiding the `Range:` prefix.
- Existing custom profiles are migrated with the new prefix settings enabled by default.

### Fixed
- Action-bar spell/item tooltips are now re-anchored immediately and continuously, preventing them from jumping back to Blizzard's default action-bar tooltip position.
- Cursor positioning is applied when the tooltip owner is assigned, when the tooltip is shown and while it remains visible.

### Notes
- Original Blizzard spell, item and action tooltip content is preserved.
- OnPoint remains Beta while WoW Forever Build 70009 compatibility is tested.

## 1.1 — Beta — 26.09.2026
- Expanded Info tab with version, build date, compatibility, author, Discord contact, slash commands, Beta status and UI-only notice.
- Added community-ready documentation and changelog.

## 1.0 — 26.09.2026
- First named release.
- Cursor tooltip positioning, profiles, live preview, minimap button, range display and health/resource bars.
