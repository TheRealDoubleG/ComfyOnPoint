# OnPoint Changelog

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
