# CLAUDE.md — Amplibre

## Project Overview

Amplibre is a native macOS 26 Winamp-inspired music player built with SwiftUI, AppKit, and Swift 6.2. It renders pixel-perfect Winamp classic skins (.wsz), plays local audio via AVAudioEngine, discovers music via MusicKit/ITunesLibrary, streams from Bandcamp and Apple Music, scrobbles to Last.fm, and backs up DRM-free music to external volumes.

## Build & Run

```bash
swift build                    # Build with SPM
swift test                     # Run all tests
```

No `.xcodeproj` currently — pure SPM build. XcodeGen integration may be added later.

## Architecture

- **Swift 6.2** with `ApproachableConcurrency` and `DefaultIsolation(MainActor.self)`
- **Modular monolith** — six framework targets:
  - `AmplibreCore` — models, protocols, utilities (SwiftData, Crypto, KeychainAccess)
  - `SkinEngine` — WSZ parsing, BMP decoding, sprite extraction (ZIPFoundation)
  - `AudioCore` — AVAudioEngine graph, EQ, crossfade, visualization tap
  - `AmplibreUI` — skin-rendered windows (AppKit) + modern views (SwiftUI)
  - `LibraryManager`, `StreamBridge`, `ScrobbleService`, `ExportEngine` — future milestones
- App target: `Amplibre` (executable, imports all frameworks)
- Types shared across modules must be `public`
- `@Observable` for UI-bound state; `@Model` (SwiftData) for persistence

## SPM Dependencies

| Package | Purpose |
|---------|---------|
| ZIPFoundation | WSZ archive extraction |
| swift-crypto | SHA-256 checksums, MD5 for Last.fm |
| KeychainAccess | OAuth tokens & session keys |
| swift-snapshot-testing | Pixel-level skin rendering tests |

## Code Conventions

- **macOS only** — no `#if os(iOS)` needed
- Skin windows use **AppKit** (NSWindow/NSView) for pixel-precise bitmap rendering
- Modern panels use **SwiftUI** (library browser, preferences, skin browser)
- Integer scaling only (1×, 2×, 3×) with nearest-neighbor interpolation
- BMP decoding is custom (not CoreGraphics) to handle all Winamp skin variants

## Key Files

- `Package.swift` — SPM config, all targets and dependencies
- `App/AmplibreApp.swift` — @main entry point
- `App/Info.plist` — privacy descriptions (MusicKit access)
- `App/Amplibre.entitlements` — sandbox, network, files, MusicKit
- `Sources/SkinEngine/BMPDecoder.swift` — custom BMP reader (8/16/24/32-bit, RLE)
- `Sources/SkinEngine/WSZArchiveParser.swift` — WSZ file parser
- `Sources/SkinEngine/SkinCache.swift` — skin asset cache, implements SkinProvider
- `Sources/AudioCore/AudioEngine.swift` — AVAudioEngine graph manager

## Common Pitfalls

- `KeychainAccess.Keychain` is not Sendable — use `nonisolated(unsafe)` for static instances, `@preconcurrency import`
- `UserDefaults` is not Sendable — same approach
- Types in `AmplibreCore` used by other modules need `public` access control
- BMP files in Winamp skins use bottom-up row order by default (pixel 0,0 is bottom-left)
- Skin filenames in WSZ archives have inconsistent casing — always match case-insensitively
- The first pixel (0,0) of each skin BMP defines the transparent color

## Testing

Tests use Swift Testing (`import Testing`, `@Test`, `@Suite`). Always `import Foundation` in test files (DefaultIsolation removes auto-import).

```bash
swift test                                    # Run all tests
swift test --filter SkinEngineTests           # Run specific suite
swift test --filter AmplibreCoreTests         # Run specific suite
```

## Approach Guidelines

### Act Directly
- Bug fixes, small UI changes, single-file modifications
- Clear, well-defined tasks with obvious implementation

### Use Plan Mode
- New features affecting multiple files or services
- Architectural changes or refactors
- New framework targets or module boundaries
- Skin rendering pipeline changes

### Avoid Over-Engineering
- No abstractions for one-time operations
- No speculative features or "just in case" code
- Three similar lines > premature abstraction
- Trust SwiftUI/SwiftData/AVAudioEngine framework guarantees

## Git Workflow

### Commits
- Only commit when explicitly asked
- Add specific files, never `git add .` or `git add -A`
- Concise message focusing on "why", end with `Co-Authored-By` line
- Never skip hooks, never force push to main

## Implementation Status

### Milestone 1: Skeleton + Skin Engine (Weeks 1–4)
- [x] Week 1: Project setup, SPM workspace, framework targets, dependencies, entitlements, CI
- [ ] Week 2: BMP decoder + WSZ parser (full implementation with tests)
- [ ] Week 3: Sprite extraction + skin model (full coordinate maps)
- [ ] Week 4: Main window rendering (NSWindow/NSView with skin compositing)

### Milestone 2–6: See Amplibre_Implementation_Plan.md
