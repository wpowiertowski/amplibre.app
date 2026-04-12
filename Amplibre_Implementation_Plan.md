# Amplibre — Implementation Plan

### A Winamp-Inspired Open-Source Music Player for macOS Tahoe

**Target:** Swift 6.3 · Xcode 26 · macOS 26 SDK · amplibre.app

**Last Updated:** April 2026

---

## Overview

This document is the engineering implementation plan for Amplibre. It translates the architecture document into actionable milestones, package structure, file-level breakdowns, dependency choices, and sprint-level tasks. It is written for the developer(s) building the project and assumes familiarity with the [Architecture Document](./Amplibre_Architecture_Document.md).

The plan is organized in **6 milestones** across an estimated **20-week** timeline for a solo developer (faster with contributors). Each milestone produces a shippable, testable increment.

---

## Swift & Xcode Baseline

### Swift 6.3 (Released March 24, 2026)

Amplibre targets **Swift 6.3**, the latest stable release, which ships with Xcode 26.3+. Key language features we will leverage:

| Feature | How Amplibre Uses It |
|---|---|
| **Approachable Concurrency** (Swift 6.2+) | `defaultIsolation = MainActor` for the entire UI layer. All code runs on the main actor unless explicitly marked `@concurrent`. Eliminates accidental data races in the skin renderer and playlist manager. |
| **`@concurrent` attribute** | Audio engine tap callbacks and FFT computation run off the main actor. Export engine file I/O is `@concurrent` to avoid blocking UI. |
| **`nonisolated(nonsending)` default** | Async functions inherit the caller's isolation context. The skin parser's async loading methods stay on MainActor when called from UI, but run concurrently when called from background tasks. |
| **`InlineArray`** (Swift 6.2+) | `[10 of Float]` for EQ band gain arrays. `[76 of UInt8]` for spectrum analyzer bar heights. Fixed-size, stack-allocated, no heap overhead in the hot audio path. |
| **`Span`** (Swift 6.2+) | Safe access to PCM audio buffers from AVAudioEngine tap callbacks without `UnsafeBufferPointer`. |
| **`@c` attribute** (Swift 6.3) | Expose the BMP parser's low-level decoding functions to a potential C-based performance-critical path if profiling reveals bottlenecks. |
| **Modern `NotificationCenter`** (Swift 6.2+) | Typed notifications for `NowPlayingChanged`, `SkinDidLoad`, `ExportProgress` with concrete payloads instead of string-keyed dictionaries. |
| **`Observations` async sequence** (Swift 6.2+) | Stream transactional state changes from `@Observable` models (e.g., `PlaybackState`, `EQState`) to SwiftUI views with coalesced updates. |
| **Named Tasks** (Swift 6.2+) | All background tasks carry descriptive names (`"SkinParser"`, `"LibraryScan"`, `"ScrobbleFlush"`) for Instruments profiling and LLDB debugging. |
| **Swift Testing** (Swift 6.2+) | Exit tests for crash-safety validation of malformed WSZ files. Attachments for snapshot test failures. Parameterized tests across all 18 EQ presets. |
| **Subprocess package** (Swift 6.2+) | Shell out to `ffprobe` for edge-case format detection during library scanning, if needed. |

### Xcode 26 Features Used

| Feature | Usage |
|---|---|
| **AI Coding Assistant** | Use Claude/ChatGPT integration for boilerplate generation (SwiftData models, test stubs) |
| **#Playground macro** | Rapid prototyping of skin rendering logic, EQ curves, and BMP parsing without full app builds |
| **Swift Build (open-source)** | CI builds on GitHub Actions using the open-source build engine |
| **Processor Trace** (M4) | Profile the hot audio path and skin rendering pipeline at branch-decision level |
| **Icon Composer** | Create Liquid Glass layered app icon with Amplibre branding |

---

## Package & Module Structure

```
Amplibre/
├── Package.swift                     # SPM workspace definition
├── App/
│   ├── AmplibreApp.swift             # @main entry point
│   ├── AppDelegate.swift             # NSApplicationDelegate for menu bar, dock icon
│   └── Info.plist
├── Sources/
│   ├── AmplibreCore/                 # Framework: models, protocols, utilities
│   │   ├── Models/
│   │   │   ├── LibraryItem.swift     # SwiftData @Model
│   │   │   ├── Playlist.swift
│   │   │   ├── EQPreset.swift
│   │   │   ├── SkinMetadata.swift
│   │   │   ├── ScrobbleEntry.swift
│   │   │   └── ExportManifest.swift
│   │   ├── Protocols/
│   │   │   ├── StreamSource.swift    # Protocol for Bandcamp/Apple Music
│   │   │   ├── SkinProvider.swift    # Protocol for skin asset access
│   │   │   ├── AudioInputPlugin.swift
│   │   │   ├── VisualizationPlugin.swift
│   │   │   └── GeneralPlugin.swift
│   │   ├── Utilities/
│   │   │   ├── KeychainManager.swift
│   │   │   ├── FileHasher.swift      # SHA-256 for export verification
│   │   │   └── Preferences.swift     # UserDefaults wrapper
│   │   └── Extensions/
│   │       ├── CGImage+BMP.swift     # BMP sprite extraction helpers
│   │       └── URL+Skin.swift
│   │
│   ├── SkinEngine/                   # Framework: WSZ parsing & rendering
│   │   ├── WSZArchiveParser.swift    # ZIP extraction, case-insensitive lookup
│   │   ├── BMPDecoder.swift          # Custom BMP reader (8/16/24/32-bit, RLE)
│   │   ├── SpriteExtractor.swift     # Pixel-coord slicing per skin spec
│   │   ├── SkinFontAtlas.swift       # text.bmp → character map
│   │   ├── SkinDigitRenderer.swift   # numbers.bmp → time display
│   │   ├── SkinColorConfig.swift     # pledit.txt, viscolor.txt parsing
│   │   ├── SkinRegion.swift          # region.txt polygon parsing
│   │   ├── SkinCache.swift           # In-memory CGImage cache keyed by element+state
│   │   ├── SkinBrowser/
│   │   │   ├── SkinMuseumClient.swift    # HTTPS client for skins.webamp.org
│   │   │   ├── SkinBrowserView.swift     # SwiftUI browser with thumbnails
│   │   │   └── SkinDownloadManager.swift # Background download + install
│   │   └── Tests/
│   │       ├── BMPDecoderTests.swift
│   │       ├── SpriteExtractorTests.swift
│   │       └── SkinSnapshotTests.swift   # Pixel comparison vs Webamp screenshots
│   │
│   ├── AudioCore/                    # Framework: playback, EQ, DSP
│   │   ├── AudioEngine.swift         # AVAudioEngine graph setup & management
│   │   ├── PlayerNode.swift          # Dual AVAudioPlayerNode for crossfade
│   │   ├── CrossfadeController.swift # Volume ramp timing, equal-power curve
│   │   ├── EQController.swift        # 10-band AVAudioUnitEQ mapped to Winamp freqs
│   │   ├── EQPresetManager.swift     # Load/save/import .eqf presets
│   │   ├── ReplayGainReader.swift    # ID3v2/Vorbis/SoundCheck RG tag extraction
│   │   ├── VisualizationTap.swift    # installTap → FFT + waveform data
│   │   ├── SpectrumAnalyzer.swift    # vDSP FFT, logarithmic binning to 76 bands
│   │   ├── AudioFormats.swift        # Format detection, metadata extraction
│   │   └── Tests/
│   │       ├── EQControllerTests.swift
│   │       ├── CrossfadeTests.swift
│   │       └── SpectrumAnalyzerTests.swift
│   │
│   ├── LibraryManager/              # Framework: music discovery & catalog
│   │   ├── ITunesLibraryBridge.swift # ITunesLibrary.framework wrapper
│   │   ├── MusicKitBridge.swift      # MusicKit async queries
│   │   ├── LibrarySyncEngine.swift   # Merge both sources into unified catalog
│   │   ├── MetadataEnricher.swift    # Background artwork + tag completion
│   │   ├── LocalFileScanner.swift    # Folder watch for drag-drop imports
│   │   └── Tests/
│   │       └── LibrarySyncTests.swift
│   │
│   ├── StreamBridge/                 # Framework: streaming integrations
│   │   ├── BandcampClient.swift      # OAuth 2.0, collection sync, streaming URLs
│   │   ├── BandcampAuthFlow.swift    # ASWebAuthenticationSession flow
│   │   ├── AppleMusicAdapter.swift   # MusicKit ApplicationMusicPlayer wrapper
│   │   ├── StreamSourceRouter.swift  # Routes playback to correct backend
│   │   └── Tests/
│   │       └── BandcampClientTests.swift
│   │
│   ├── ScrobbleService/             # Framework: Last.fm integration
│   │   ├── LastFMClient.swift        # HTTP client with MD5 API signing
│   │   ├── LastFMAuthFlow.swift      # Token → session key exchange
│   │   ├── ScrobbleQueue.swift       # SwiftData-backed offline queue
│   │   ├── NowPlayingReporter.swift  # track.updateNowPlaying calls
│   │   └── Tests/
│   │       ├── LastFMClientTests.swift
│   │       └── ScrobbleQueueTests.swift
│   │
│   ├── ExportEngine/                # Framework: backup to external volume
│   │   ├── ExportableContentFilter.swift  # DRM detection, purchase status check
│   │   ├── ExportPipeline.swift           # Manifest diff → file copy → verify
│   │   ├── VolumeWatcher.swift            # NSWorkspace disk mount notifications
│   │   ├── ChecksumVerifier.swift         # SHA-256 post-copy validation
│   │   ├── ExportScheduler.swift          # Timer + volume-mount triggers
│   │   └── Tests/
│   │       ├── ExportableContentFilterTests.swift
│   │       └── ExportPipelineTests.swift
│   │
│   └── AmplibreUI/                  # Framework: all UI
│       ├── SkinWindows/
│       │   ├── WinampWindow.swift         # NSWindow subclass: borderless, dockable
│       │   ├── DockingEngine.swift        # Magnetic snap, group drag, edge detection
│       │   ├── MainWindowView.swift       # NSView: composites main.bmp + interactive elements
│       │   ├── EQWindowView.swift         # NSView: eqmain.bmp + slider interaction
│       │   ├── PlaylistWindowView.swift   # NSView: pledit.bmp chrome + NSTableView
│       │   ├── TitleTicker.swift          # CoreAnimation scrolling text.bmp font
│       │   ├── TimeDisplay.swift          # numbers.bmp digit compositing
│       │   ├── TransportButtons.swift     # cbuttons.bmp state machine
│       │   ├── VolumeSlider.swift         # volume.bmp 28-frame slider
│       │   ├── BalanceSlider.swift        # balance.bmp or derived from volume
│       │   ├── PositionBar.swift          # posbar.bmp seek control
│       │   ├── ShuffleRepeatButtons.swift # shufrep.bmp toggle states
│       │   ├── MonoStereoIndicator.swift  # monoster.bmp
│       │   ├── PlayPauseIndicator.swift   # playpaus.bmp LED states
│       │   └── WindowShadeMode.swift      # Collapsed mini-mode from titlebar.bmp
│       ├── ModernViews/
│       │   ├── LibraryBrowserView.swift   # SwiftUI + Liquid Glass sidebar
│       │   ├── PreferencesView.swift      # SwiftUI settings panel
│       │   ├── SkinBrowserSheet.swift     # SwiftUI skin museum browser
│       │   ├── ExportProgressView.swift   # SwiftUI export status
│       │   └── LastFMConnectView.swift    # SwiftUI auth flow UI
│       ├── Visualization/
│       │   ├── SpectrumView.swift         # 76×16 skin-area spectrum bars
│       │   ├── OscilloscopeView.swift     # 76×16 waveform display
│       │   └── MetalVisualizationView.swift # Full-window Metal shader viz
│       └── Tests/
│           ├── DockingEngineTests.swift
│           └── UISnapshotTests.swift
│
├── Resources/
│   ├── Assets.xcassets/              # App icon (Liquid Glass layers via Icon Composer)
│   ├── base-2.91.wsz                # Default Winamp 2.91 skin (bundled)
│   ├── EQPresets/
│   │   └── Winamp.q1                # Original 18 Winamp EQ presets
│   └── demo.mp3                     # "It really whips the llama's ass" (if licensable, else omit)
│
└── CI/
    ├── .github/workflows/
    │   ├── build.yml                 # Swift Build on macOS runner
    │   ├── test.yml                  # Unit + snapshot tests
    │   └── release.yml               # Notarize + DMG + App Store upload
    └── Fastfile                      # Fastlane config for signing & distribution
```

---

## Dependencies

### Swift Packages (SPM)

| Package | Version | Purpose | License |
|---|---|---|---|
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | 0.9+ | WSZ archive extraction | MIT |
| [swift-crypto](https://github.com/apple/swift-crypto) | 3.0+ | SHA-256 checksums for export verification, MD5 for Last.fm API signing | Apache 2.0 |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) | 4.2+ | Ergonomic Keychain wrapper for OAuth tokens & session keys | MIT |
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) | 1.15+ | Pixel-level skin rendering tests vs Webamp reference images | MIT |

### System Frameworks (No SPM Required)

| Framework | Usage |
|---|---|
| `AVFAudio` / `AVFoundation` | Audio engine, playback, EQ, mixer |
| `MusicKit` | Apple Music catalog, library queries, subscription check |
| `iTunesLibrary` | Local library access, file URLs, purchase status |
| `Accelerate` (vDSP) | FFT for spectrum analyzer, loudness analysis |
| `Metal` / `MetalKit` | Shader-based extended visualizations |
| `CoreGraphics` | BMP image compositing, skin rendering |
| `CoreAnimation` | Title ticker scrolling, smooth animations |
| `SwiftData` | Persistent models (library, playlists, scrobble queue, manifests) |
| `SwiftUI` | Modern panels (library browser, preferences, skin browser) |
| `AppKit` | Pixel-precise skin windows, docking, NSTableView playlist |
| `Security` | Keychain access for credentials |
| `ASWebAuthenticationSession` | OAuth flows (Bandcamp, Last.fm) |

### No External Dependencies For

- **BMP Decoding** — Custom implementation required. CoreGraphics `CGImage` cannot parse all BMP variants found in community skins (8-bit indexed, BI_RLE8, unusual bit depths). A ~400-line Swift BMP decoder covers all cases.
- **Audio Playback** — Entirely AVAudioEngine. No ffmpeg, libmpv, or VLC.
- **Networking** — URLSession + async/await. No Alamofire.
- **JSON** — Codable. No SwiftyJSON.

---

## Milestone 1: Skeleton + Skin Engine (Weeks 1–4)

**Goal:** Open a WSZ file, parse all bitmaps, render the main window with the default skin. No audio.

### Week 1: Project Setup

- [ ] Create Xcode 26 project with SPM workspace structure
- [ ] Configure Swift 6.3 language version, enable `ApproachableConcurrency`, `DefaultIsolation(MainActor.self)`
- [ ] Add all SPM dependencies (ZIPFoundation, swift-crypto, KeychainAccess, swift-snapshot-testing)
- [ ] Set up framework targets: `AmplibreCore`, `SkinEngine`, `AmplibreUI`
- [ ] Configure entitlements: sandbox, network client, user-selected files read-write, MusicKit
- [ ] Set up GitHub repo with CI workflow (build + test on macOS runner)
- [ ] Bundle `base-2.91.wsz` as the default skin resource

### Week 2: BMP Decoder + WSZ Parser

- [ ] Implement `BMPDecoder`: parse BMP file header, DIB header (BITMAPINFOHEADER, BITMAPV4HEADER, BITMAPV5HEADER)
- [ ] Support pixel formats: 1-bit, 4-bit, 8-bit indexed (with palette), 16-bit (555/565), 24-bit RGB, 32-bit ARGB
- [ ] Support compression: BI_RGB (uncompressed), BI_RLE8, BI_RLE4, BI_BITFIELDS
- [ ] Handle bottom-up (standard) and top-down row order
- [ ] Output: `CGImage` with premultiplied alpha
- [ ] Implement `WSZArchiveParser`: extract ZIP via ZIPFoundation, case-insensitive filename resolution
- [ ] Handle skins with files at root vs. in a single subdirectory
- [ ] Write unit tests: decode base-2.91 skin BMPs, verify dimensions match spec
- [ ] Fuzz test: feed 50 random malformed BMP headers, verify no crash

### Week 3: Sprite Extraction + Skin Model

- [ ] Implement `SpriteExtractor` with the full pixel coordinate map from the architecture document appendix
- [ ] Extract all main.bmp regions (background, viz area, time display, ticker, transport, volume, balance, position bar, etc.)
- [ ] Extract cbuttons.bmp: 5 buttons × 2 states (normal, pressed) = 10 sprites
- [ ] Extract shufrep.bmp: shuffle (on/off × normal/pressed), repeat (on/off × normal/pressed), EQ toggle, PL toggle
- [ ] Extract volume.bmp: 28 background frames + thumb (normal, pressed)
- [ ] Extract posbar.bmp: background + thumb (normal, pressed)
- [ ] Extract numbers.bmp: 11 digit sprites (0–9, blank)
- [ ] Extract text.bmp: full character map (A–Z, 0–9, symbols) → `SkinFontAtlas`
- [ ] Extract monoster.bmp, playpaus.bmp indicator sprites
- [ ] Implement transparency: first pixel (0,0) of each BMP defines the magic transparent color
- [ ] Parse `pledit.txt` → playlist colors, `viscolor.txt` → 24-color visualization palette
- [ ] Implement `SkinCache`: dictionary of `[SkinElement: [SkinState: CGImage]]`
- [ ] Write snapshot tests: compare extracted sprites from base-2.91 against known-good reference images

### Week 4: Main Window Rendering

- [ ] Implement `WinampWindow` (NSWindow subclass): borderless, `styleMask: [.borderless]`, custom `isMovableByWindowBackground`
- [ ] Implement `MainWindowView` (NSView subclass): composite skin bitmaps at exact pixel positions
- [ ] Render static elements: main.bmp background, titlebar overlay (active state)
- [ ] Render time display area using `SkinDigitRenderer` (hardcoded "0:00" for now)
- [ ] Render title ticker area using `SkinFontAtlas` (hardcoded "Amplibre" scrolling)
- [ ] Implement `TitleTicker`: `CADisplayLink`-driven horizontal scroll of rendered text bitmap
- [ ] Render transport buttons from cbuttons.bmp with mouse-down/mouse-up state switching
- [ ] Render volume slider: draw the correct background frame based on a hardcoded volume level, draw thumb
- [ ] Render position bar: static background + thumb at 0%
- [ ] Support integer scaling: 1×, 2×, 3× via `CGAffineTransform` with `.none` interpolation (nearest-neighbor)
- [ ] Implement `@main` app entry that opens the main window with the default skin
- [ ] **Milestone 1 deliverable:** App launches and shows a pixel-perfect rendered Winamp main window. Buttons animate on click. Nothing plays yet.

---

## Milestone 2: Audio Engine + Playback (Weeks 5–8)

**Goal:** Play local audio files through the skin-rendered UI with EQ, visualization, and crossfade.

### Week 5: AVAudioEngine Pipeline

- [ ] Implement `AudioEngine`: configure the node graph: `PlayerNode → EQNode → Mixer → Output`
- [ ] Implement dual `AVAudioPlayerNode` setup for crossfading
- [ ] Wire `EQController` with `AVAudioUnitEQ` (10 bands at Winamp frequencies: 70, 180, 320, 600, 1K, 3K, 6K, 12K, 14K, 16K Hz)
- [ ] Use `InlineArray` for the 10-band gain array: `var gains: [10 of Float]`
- [ ] Implement `ReplayGainReader`: parse RG tags from ID3v2 (TXXX), Vorbis Comment, and iTunes Sound Check
- [ ] Implement play, pause, stop, next, previous commands
- [ ] Wire transport buttons in `MainWindowView` to `AudioEngine` commands
- [ ] Implement position seek: `posbar` thumb drag → `AudioEngine.seek(to:)`
- [ ] Implement volume control: `VolumeSlider` drag → `AudioEngine.volume`
- [ ] Implement balance control: `BalanceSlider` drag → left/right channel gain

### Week 6: Visualization + Time Display

- [ ] Implement `VisualizationTap`: `installTap(onBus:bufferSize:format:)` on the mixer output
- [ ] Use `Span` for safe access to the PCM buffer data in the tap callback
- [ ] Implement `SpectrumAnalyzer`: 512-point FFT via `vDSP.FFT`, logarithmic frequency binning to 76 bars
- [ ] Use `InlineArray` for the bar heights: `var bars: [76 of UInt8]`
- [ ] Implement `SpectrumView`: render 76 bars in the 76×16 pixel skin area using `viscolor.txt` palette
- [ ] Implement peak indicator decay (2px/frame fall rate)
- [ ] Implement `OscilloscopeView`: downsample PCM to 76 points, render waveform centered in 16px height
- [ ] Toggle between spectrum/oscilloscope/off via clutterbar click (matching Winamp behavior)
- [ ] Wire `TimeDisplay` to update from `AudioEngine.currentTime` using `SkinDigitRenderer`
- [ ] Implement elapsed/remaining toggle on time display click
- [ ] Update `MonoStereoIndicator` based on current track's channel count
- [ ] Update `PlayPauseIndicator` LED based on playback state

### Week 7: Playlist + Drag-Drop

- [ ] Implement `PlaylistWindowView`: render pledit.bmp chrome (title bar, scrollbar, resize handle, bottom buttons)
- [ ] Embed an `NSTableView` within the chrome area, styled with `pledit.txt` colors
- [ ] Implement playlist model: ordered array of `LibraryItem`, persistent via SwiftData
- [ ] Drag-and-drop: accept audio file URLs from Finder → add to playlist
- [ ] Double-click row → play that track
- [ ] Implement Add/Remove/Select/Misc button menus (matching Winamp's bottom-bar buttons)
- [ ] Implement playlist sorting: by title, filename, path, reverse, randomize
- [ ] Implement M3U/PLS import and export
- [ ] Show total time and selected time in the playlist footer

### Week 8: Crossfade + EQ Window

- [ ] Implement `CrossfadeController`: configurable overlap (0–12 seconds)
- [ ] Equal-power crossfade curve (sine interpolation) between dual PlayerNodes
- [ ] Implement `EQWindowView`: render eqmain.bmp background
- [ ] Render 10 vertical sliders + preamp slider with mouse interaction
- [ ] Wire sliders to `EQController` band gains in real-time
- [ ] Implement EQ on/off toggle and auto-load toggle buttons
- [ ] Implement `EQPresetManager`: load built-in Winamp presets from bundled `Winamp.q1`
- [ ] Implement preset save/load UI (presets button → popup menu)
- [ ] Import Winamp `.eqf` preset files
- [ ] **Milestone 2 deliverable:** App plays local audio files with full skin UI, working EQ, spectrum analyzer, crossfade, and playlist management.

---

## Milestone 3: Library Discovery + Skin Browser (Weeks 9–12)

**Goal:** Auto-discover the user's music library, browse/download skins, window docking.

### Week 9: ITunesLibrary + MusicKit Integration

- [ ] Implement `ITunesLibraryBridge`: initialize `ITLibrary`, enumerate all `ITLibMediaItem`s
- [ ] Extract: file URL, title, artist, album, genre, duration, play count, rating, date added, artwork
- [ ] Classify each item: purchased (DRM-free), matched (iTunes Match), ripped, local file, Apple Music (DRM)
- [ ] Implement `MusicKitBridge`: `MusicAuthorization.request()`, `MusicLibraryRequest` for songs/albums/playlists
- [ ] Implement `MusicSubscription` check to gate Apple Music streaming features
- [ ] Implement `LibrarySyncEngine`: merge both sources into unified `LibraryItem` SwiftData models
- [ ] Deduplicate by matching title + artist + duration (within 2-second tolerance)
- [ ] Track provenance: `.local`, `.purchased`, `.matched`, `.appleMusic`, `.bandcamp`
- [ ] Background scan on launch using a named `Task("LibraryScan")`
- [ ] Periodic rescan with change detection (new, modified, removed tracks)

### Week 10: Library Browser UI

- [ ] Implement `LibraryBrowserView` in SwiftUI with `NavigationSplitView`
- [ ] Sidebar: Artists, Albums, Genres, Playlists, Smart Playlists
- [ ] Detail view: track list with columns (title, artist, album, duration, format, provenance icon)
- [ ] Search bar with real-time filtering
- [ ] Apply Liquid Glass material to the sidebar and toolbar via `.glassEffect(.regular)`
- [ ] Double-click or Enter → add to playlist and play
- [ ] Context menu: Add to Playlist, Show in Finder, Get Info, Export
- [ ] Host the SwiftUI view in an `NSWindow` that participates in the docking system

### Week 11: Skin Browser + Download

- [ ] Implement `SkinMuseumClient`: fetch skin metadata + thumbnails from skins.webamp.org
- [ ] API: `https://skins.webamp.org/skin/{md5}/{filename}` for direct WSZ download
- [ ] Implement `SkinBrowserView` (SwiftUI): searchable grid of skin thumbnails with preview
- [ ] Implement `SkinDownloadManager`: background download, save to `~/Library/Application Support/Amplibre/Skins/`
- [ ] Skin switcher: `Cmd+S` opens skin browser, selecting a skin reloads all windows instantly
- [ ] Implement local skin management: list installed skins, delete, set as default
- [ ] Drag-and-drop WSZ files from Finder → auto-install and apply

### Week 12: Window Docking + Window Shade

- [ ] Implement `DockingEngine`: calculate edge proximity between all visible WinampWindows
- [ ] Snap threshold: 10px (configurable in preferences)
- [ ] When docked, windows form a group: dragging one moves all docked windows together
- [ ] Implement screen edge snapping
- [ ] Implement `WindowShadeMode`: double-click title bar → collapse to shade mode
- [ ] Shade mode uses the shade-region graphics from titlebar.bmp (row 2 of the sprite sheet)
- [ ] Each window independently togglable between normal and shade mode
- [ ] Implement always-on-top toggle (Ctrl+A matching Winamp)
- [ ] **Milestone 3 deliverable:** Full library discovery, browsable skin museum with one-click install, magnetic window docking. The app feels like a complete local music player.

---

## Milestone 4: Streaming + Scrobbling (Weeks 13–16)

**Goal:** Stream from Bandcamp and Apple Music, scrobble to Last.fm.

### Week 13: Bandcamp Integration

- [ ] Register for Bandcamp API access (contact Bandcamp with app description)
- [ ] Implement `BandcampAuthFlow`: OAuth 2.0 via `ASWebAuthenticationSession`
- [ ] Store access token + refresh token in Keychain
- [ ] Implement automatic token refresh (1-hour expiry)
- [ ] Implement `BandcampClient`: fetch user's purchased collection (albums, tracks)
- [ ] Map Bandcamp tracks to `LibraryItem` with `.bandcamp` provenance
- [ ] Implement streaming playback via Bandcamp's streaming URLs through `AVAudioPlayerNode`
- [ ] Implement high-quality download (FLAC/MP3) for purchased tracks with download rights
- [ ] Display Bandcamp collection in the Library Browser with Bandcamp icon badge

### Week 14: Apple Music Streaming

- [ ] Implement `AppleMusicAdapter`: wrap `ApplicationMusicPlayer` behind `StreamSource` protocol
- [ ] Implement catalog search: `MusicCatalogSearchRequest` → results in Library Browser
- [ ] Implement playback: `ApplicationMusicPlayer.shared.queue` management
- [ ] Observe `ApplicationMusicPlayer.shared.queue.currentEntry` for now-playing updates
- [ ] Wire now-playing info to title ticker, time display
- [ ] Handle DRM limitation: display notification when EQ/visualization unavailable for DRM content
- [ ] Implement `StreamSourceRouter`: detect track provenance → route to correct playback backend

### Week 15: Last.fm Scrobbling

- [ ] Implement `LastFMClient`: HTTP client with MD5 API signature generation
- [ ] API base URL: `https://ws.audioscrobbler.com/2.0/`
- [ ] Implement `LastFMAuthFlow`: redirect to Last.fm auth page → receive token → exchange for session key
- [ ] Store session key in Keychain (persistent, no expiry unless revoked)
- [ ] Implement `NowPlayingReporter`: call `track.updateNowPlaying` when a track starts
- [ ] Implement scrobble trigger: track > 30 seconds AND (listened > 50% OR listened > 4 minutes)
- [ ] Implement `ScrobbleQueue` (SwiftData-backed):
  - [ ] Queue scrobbles when offline or on API error
  - [ ] Flush on connectivity restoration with exponential backoff
  - [ ] Batch submission (up to 50 per request)
  - [ ] Discard entries older than 14 days (Last.fm's submission window)
  - [ ] Persist across app restarts
- [ ] Implement `LastFMConnectView` (SwiftUI): connect/disconnect, show profile, recent scrobbles
- [ ] Scrobble from all sources: local files, Apple Music, Bandcamp

### Week 16: Scrobble Polish + Streaming Edge Cases

- [ ] Handle network transitions gracefully (Wi-Fi → cellular → offline → back)
- [ ] Implement retry logic for Last.fm error codes 11 (Service Offline) and 16 (Temporarily Unavailable)
- [ ] Implement re-authentication flow for error code 9 (Invalid Session Key)
- [ ] Handle Bandcamp stream interruptions: buffer underrun → retry with backoff
- [ ] Handle Apple Music subscription expiry: gracefully degrade, hide Apple Music content
- [ ] Write integration tests: mock Last.fm server, verify scrobble queue flush behavior
- [ ] **Milestone 4 deliverable:** Stream from Bandcamp and Apple Music, scrobble everything to Last.fm with offline resilience.

---

## Milestone 5: Export Engine (Weeks 17–18)

**Goal:** Backup DRM-free music to external volumes with verification.

### Week 17: Export Pipeline

- [ ] Implement `ExportableContentFilter`:
  - [ ] Use `ITLibMediaItem.locationType` and `ITLibMediaItem.location` to find local files
  - [ ] Check for FairPlay DRM: attempt to read the file header for `drms` or `mp4a` atom with `sinf` box
  - [ ] Classify: exportable (purchased DRM-free, matched, ripped, local) vs. non-exportable (Apple Music DRM)
- [ ] Implement volume selection: `NSOpenPanel` restricted to mounted volumes
- [ ] Verify write permissions and available disk space before starting
- [ ] Implement `ExportPipeline`:
  - [ ] Generate manifest: list of (source path, destination path, SHA-256 hash)
  - [ ] Directory structure: `/Amplibre Backup/Artist/Album/## - Title.ext`
  - [ ] Sanitize filenames: remove characters illegal on FAT32/exFAT (`<>:"/\|?*`)
  - [ ] Copy files with `FileManager.copyItem(at:to:)` on a `@concurrent` task
  - [ ] Report progress via `@Observable` `ExportProgress` model → `ExportProgressView`
  - [ ] Post-copy SHA-256 verification via `swift-crypto`
  - [ ] Write JSON sidecar (`.amplibre-meta.json`) with original metadata per file

### Week 18: Incremental Sync + Scheduling

- [ ] Implement `ExportManifest` (SwiftData): volume UUID, last sync date, per-track records
- [ ] Incremental sync: diff current library against manifest → copy only new/modified tracks
- [ ] Handle deleted tracks: optional removal from backup (user preference)
- [ ] Implement `VolumeWatcher`: `NSWorkspace.shared.notificationCenter` for `didMountNotification`
- [ ] Auto-trigger incremental sync when designated backup volume is mounted
- [ ] Implement `ExportScheduler`: configurable schedule (daily/weekly/monthly) using `Timer` or `BGTaskScheduler`
- [ ] Generate summary report: success count, failure count, skipped (DRM) count, total size copied
- [ ] `ExportProgressView` (SwiftUI): real-time progress bar, file-by-file status, estimated time remaining
- [ ] **Milestone 5 deliverable:** One-click backup of all owned music to external drive. Incremental sync. Auto-trigger on volume mount.

---

## Milestone 6: Polish + Release (Weeks 19–20)

**Goal:** Production quality. Ship it.

### Week 19: Polish & Edge Cases

- [ ] Implement global keyboard shortcuts (media keys: play/pause, next, prev, volume up/down)
- [ ] Implement `Cmd+O` → open file dialog
- [ ] Implement `Cmd+L` → open URL (for stream URLs)
- [ ] Implement menu bar integration: File, Playback, Playlist, View, Skins, Help menus
- [ ] Implement Dock icon: right-click → playback controls, now playing info
- [ ] Implement `NSUserActivity` for Handoff / Spotlight indexing of playlists
- [ ] Implement macOS Media Session (Now Playing widget in Control Center / menu bar)
- [ ] Handle edge cases: empty playlists, missing files, corrupted skins, network failures
- [ ] Performance profiling with Instruments: ensure skin rendering < 16ms, FFT visualization > 30fps
- [ ] Memory profiling: ensure no leaks during skin switching, playlist scrolling, long playback sessions
- [ ] Accessibility: VoiceOver labels for all transport controls, playlist items, EQ sliders
- [ ] Localization: extract all user-facing strings to String Catalogs (English + framework for community translations)

### Week 20: Testing, Packaging & Release

- [ ] Run full snapshot test suite against 100 reference skins from the Webamp museum
- [ ] Run fuzz tests on WSZ parser with 1000 malformed archives
- [ ] Run integration test suite: library sync, scrobble round-trip, export pipeline
- [ ] Fix all critical and high-severity bugs
- [ ] Create app icon using Xcode 26 Icon Composer (Liquid Glass layers)
- [ ] Build distribution DMG with background image and Applications symlink
- [ ] Sign with Developer ID, notarize via `notarytool`
- [ ] Prepare Mac App Store submission: screenshots, description, privacy nutrition labels
- [ ] Privacy labels: music library access (required), network (Last.fm/Bandcamp), file access (export)
- [ ] Publish to GitHub: MIT license, README, CONTRIBUTING.md, architecture doc, this implementation plan
- [ ] Tag v1.0.0, create GitHub Release with DMG attachment
- [ ] Submit to Mac App Store
- [ ] **Milestone 6 deliverable:** Amplibre v1.0 shipped. Open-source repo live. App Store submission pending review.

---

## Post-1.0 Roadmap

These features are explicitly deferred from v1.0 to keep scope manageable:

| Feature | Priority | Estimated Effort |
|---|---|---|
| Modern Winamp skins (.wal) support | Medium | 4 weeks |
| MilkDrop/Butterchurn visualization presets → Metal shaders | Medium | 3 weeks |
| Audio Unit v3 plugin hosting (third-party DSP) | Low | 2 weeks |
| SHOUTcast / Icecast internet radio streaming | Medium | 2 weeks |
| CD ripping (via `AudioToolbox`) | Low | 2 weeks |
| ListenBrainz scrobbling (alternative to Last.fm) | Low | 1 week |
| iOS companion app (Now Playing + remote control) | High | 6 weeks |
| Plugin SDK (Swift framework template for community plugins) | Medium | 3 weeks |
| Karaoke mode (lyrics display + vocal removal via `AudioToolbox`) | Low | 3 weeks |
| Winamp skin creator / editor tool | Low | 4 weeks |

---

## Build & CI Configuration

### Package.swift Essentials

```swift
// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Amplibre",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "Amplibre", targets: ["AmplibreApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.15.0"),
    ],
    targets: [
        .executableTarget(
            name: "AmplibreApp",
            dependencies: ["AmplibreCore", "SkinEngine", "AudioCore",
                           "LibraryManager", "StreamBridge", "ScrobbleService",
                           "ExportEngine", "AmplibreUI"],
            path: "App",
            swiftSettings: [
                .enableUpcomingFeature("DefaultIsolation(MainActor.self)"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
        // ... framework targets ...
    ]
)
```

### Xcode Build Settings

```
SWIFT_VERSION = 6.3
SWIFT_STRICT_CONCURRENCY = complete
SWIFT_APPROACHABLE_CONCURRENCY = YES
MACOSX_DEPLOYMENT_TARGET = 26.0
CODE_SIGN_IDENTITY = Apple Development
CODE_SIGN_STYLE = Automatic
ENABLE_HARDENED_RUNTIME = YES
```

---

## Key Technical Decisions

### Why AppKit for Skin Windows (Not SwiftUI)

Winamp skins require pixel-exact bitmap compositing at fixed coordinates. SwiftUI's layout engine abstracts away pixel positioning — there is no reliable way to place a 23×18 pixel button sprite at position (16, 88) within a 275×116 pixel window using SwiftUI. AppKit's `NSView.draw(_:)` with `CGContext` gives us the exact control needed. SwiftUI is used for everything that benefits from declarative UI: the library browser, preferences, skin browser, and export progress.

### Why Custom BMP Decoder (Not CoreGraphics)

CoreGraphics' `CGImageSource` with `CGImageSourceCreateWithData` handles many BMP files, but fails on skins that use:
- 8-bit indexed BMPs with non-standard palette sizes
- BI_RLE8 run-length encoding (common in older skins)
- BMPs with a BITMAPV4HEADER or V5 header (rare but present)
- BMPs where the first pixel defines transparency (CG has no API for this)

A custom decoder (~400 lines) handles all variants and integrates transparency detection.

### Why AVAudioEngine (Not AVPlayer or ApplicationMusicPlayer for Everything)

`AVPlayer` is too high-level — no access to the audio graph for EQ, visualization tap, or crossfading. `ApplicationMusicPlayer` is required for DRM-protected Apple Music content but doesn't expose PCM data. AVAudioEngine gives us the full pipeline. Apple Music playback is the only path that uses `ApplicationMusicPlayer`, and it gracefully degrades (no EQ, no visualization for DRM tracks).

### Why SwiftData (Not Core Data or SQLite)

SwiftData is the modern persistence layer for macOS 26, with `@Model` macros that integrate cleanly with SwiftUI `@Query` and `@Observable`. The data model is straightforward (no complex relationships, no migration history), making SwiftData the simplest correct choice. If performance profiling reveals issues with large libraries (50k+ tracks), we can add a raw SQLite index layer underneath.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Bandcamp API access denied or restricted | Medium | High | Build Bandcamp as an optional module. Ship v1.0 without it if needed. Fall back to web scraping of user's public collection as last resort. |
| Apple Music EQ limitation frustrates users | High | Medium | Clear UX messaging. Show "EQ unavailable for DRM content" in the EQ window. Suggest purchasing tracks for full audio control. |
| Some WSZ skins render incorrectly | Medium | Low | Ship with a "Report Skin Bug" button. Use Webamp screenshots as ground truth. Build a pixel-diff CI pipeline against top-100 most popular skins. |
| SwiftData performance with 50k+ track libraries | Low | Medium | Profile early. Add GRDB/SQLite fallback layer if needed. |
| App Store rejection for "duplicating Music.app" | Low | High | Differentiate clearly: skin support, Bandcamp, Last.fm, export features. Emphasize open-source heritage. |
| Last.fm API deprecation or rate limiting | Low | Medium | Implement ListenBrainz as backup scrobble target. Respect 2,880 scrobbles/day limit. |

---

*This implementation plan is a living document. Update it as decisions are made and priorities shift during development.*
