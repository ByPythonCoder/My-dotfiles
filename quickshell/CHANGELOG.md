# Changelog

## v2.0.0 - Popup Architecture Rewrite

### Added
- PopupManager centralized popup lifecycle
- Major/modal/OSD separation
- QuickControls replacing notification center
- Unified GlassPanel styling
- swaync theme integration
- Microphone controls
- Improved media popup
- WiFi connection dialog

### Changed
- All bar modules now communicate through PopupManager
- OSDs use unified open/close lifecycle
- Network popup embeds WiFi password dialog
- Improved popup animations and positioning

### Fixed
- Popup registration failures
- WiFi password dialog lifecycle
- OSD stacking
- Calendar popup
- Workspace overview
- Power logout
- Notification styling
