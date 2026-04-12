# Amplibre

### Architecture Document

A Winamp-Inspired Music Player for macOS Tahoe — amplibre.app

Built with Xcode 26 SDK · macOS 26 (Tahoe) · Swift · SwiftUI + AppKit

MusicKit · ITunesLibrary · Bandcamp · Apple Music · Last.fm

Full Winamp Classic Skin (.wsz) Compatibility

Version 1.0 — April 2026

## Table of Contents

1\. Executive Summary

2\. Winamp Feature Analysis

3\. System Architecture Overview

4\. Skin Engine: WSZ Compatibility Layer

5\. Audio Engine & Playback Pipeline

6\. Music Discovery: MusicKit & ITunesLibrary

7\. Library Backup & External Volume Export

8\. Streaming Integration: Bandcamp & Apple Music

9\. Last.fm Scrobbling Service

10\. UI Architecture: Windows & Docking

11\. Equalizer & DSP Pipeline

12\. Visualization Engine

13\. Plugin Architecture

14\. Data Model & Persistence

15\. Build Configuration & Deployment

16\. Security & Privacy

17\. Testing Strategy

18\. Appendix: WSZ Bitmap Specification

# 1. Executive Summary

Amplibre is a native macOS application that resurrects the spirit of Winamp — the legendary media player that defined a generation of music listening — while embracing modern Apple platform capabilities. Built for macOS 26 (Tahoe) using Xcode 26 and the latest Swift/SwiftUI frameworks, Amplibre delivers an authentic Winamp experience with pixel-perfect classic skin rendering, combined with deep integration into Apple’s music ecosystem.

The application serves three core missions:

- **Nostalgia with Fidelity:** Full compatibility with the 100,000+ Winamp classic skins (.wsz files) archived at skins.webamp.org, rendered pixel-for-pixel as they appeared in Winamp 2.9

- **Music Liberation:** Automatic discovery of all owned/purchased music via MusicKit and ITunesLibrary frameworks, with an automated backup pipeline to export DRM-free content to external volumes, protecting users against ecosystem lock-in

- **Modern Streaming:** Integrated streaming from Bandcamp (supporting independent artists) and Apple Music, with listening history exported to Last.fm via its Scrobble API 2.0

# 2. Winamp Feature Analysis

## 2.1 Classic Winamp UI Components

Winamp’s interface is built around four dockable windows, each skinnable independently. The main window is exactly 275×116 pixels and displays transport controls, a position slider, volume and balance knobs, a scrolling title ticker, a spectrum analyzer or oscilloscope, and time display using a custom LED-style digit font. The equalizer window is the same width with a 10-band graphic EQ, preamp slider, and preset management. The playlist editor is resizable vertically and shows the current queue with sorting and search. Finally, an optional minibrowser/media library window provides catalog browsing.

## 2.2 Skin System

Winamp classic skins are ZIP archives renamed to .wsz (Winamp Skin Zip). Each archive contains BMP bitmap images and text configuration files that define every visual element of the player. The skin format has remained stable since Winamp 2.0 (1998), ensuring backward compatibility across decades of community-created skins. The Webamp project has verified pixel-level accuracy for the entire 100k+ skin archive.

The format uses sprite sheets — each BMP contains multiple UI states (normal, pressed, active, inactive) packed into a single image at precise pixel coordinates. Transparency is achieved using a designated magic color (typically the first pixel of the BMP).

## 2.3 Feature Inventory

|                      |                                                          |                                                        |
|----------------------|----------------------------------------------------------|--------------------------------------------------------|
| **Feature Category** | **Winamp Capability**                                    | **Amplibre Implementation**                            |
| Transport Controls   | Play, Pause, Stop, Prev, Next with skinned button states | Native AVAudioEngine with skin bitmap overlays         |
| Position Seek        | Draggable position bar with millisecond accuracy         | Custom NSView with skin-mapped slider graphics         |
| Volume/Balance       | 28-position volume slider, balance control               | Skin-rendered sliders mapped to AVAudioEngine mixer    |
| Time Display         | LED digit font, elapsed/remaining toggle                 | Custom digit renderer using Numbers.bmp sprite sheet   |
| Title Ticker         | Scrolling marquee with custom bitmap font                | CoreAnimation-driven text scroller using Text.bmp font |
| Spectrum Analyzer    | Real-time FFT visualization with skin colors             | Accelerate.framework vDSP FFT, rendered per skin spec  |
| Oscilloscope         | Waveform display alternative to spectrum                 | vDSP waveform sampling rendered to skin area           |
| 10-Band EQ           | Graphic equalizer with presets and auto-load             | AVAudioUnitEQ mapped to classic Winamp frequency bands |
| Playlist Editor      | Drag-drop, sorting, search, M3U/PLS import/export        | NSTableView with skin chrome and playlist persistence  |
| Media Library        | Folder scanning, metadata indexing, smart views          | MusicKit + ITunesLibrary + local file indexer          |
| Window Docking       | Snap-to-edge docking between component windows           | Custom NSWindow subclass with magnetic docking logic   |
| Window Shade         | Collapsed mini-mode for each window                      | Alternate skin graphics from Titlebar.bmp shade region |
| Skins                | 100k+ community skins via WSZ format                     | Full WSZ parser with BMP sprite extraction             |
| Visualizations       | MilkDrop, AVS, and built-in analyzers                    | Metal-based visualization with shader pipeline         |
| Crossfading          | Configurable crossfade between tracks                    | Dual AVAudioPlayerNode with volume ramp                |
| Replay Gain          | Per-track and per-album volume leveling                  | ID3/Vorbis RG tag reading with gain application        |
| Streaming            | SHOUTcast/Icecast internet radio                         | Bandcamp + Apple Music streaming integration           |

# 3. System Architecture Overview

## 3.1 Technology Stack

|                 |                                                |                                                                       |
|-----------------|------------------------------------------------|-----------------------------------------------------------------------|
| **Layer**       | **Technology**                                 | **Rationale**                                                         |
| Language        | Swift 6 (strict concurrency)                   | Modern safety, performance, Apple-native                              |
| UI Framework    | SwiftUI + AppKit (hybrid)                      | SwiftUI for settings/library; AppKit for pixel-precise skin rendering |
| Audio Engine    | AVAudioEngine                                  | Low-latency, real-time DSP pipeline with mixer graph                  |
| Music Discovery | MusicKit + ITunesLibrary.framework             | Access purchased music, playlists, and file metadata                  |
| Streaming       | MusicKit (Apple Music) + URLSession (Bandcamp) | Native Apple Music playback + Bandcamp OAuth streaming                |
| Graphics        | Core Graphics + Metal                          | CG for bitmap skin rendering; Metal for visualizations                |
| Persistence     | SwiftData + UserDefaults                       | Library database, EQ presets, skin preferences                        |
| Networking      | URLSession + async/await                       | Last.fm API, Bandcamp API, skin downloads                             |
| Build System    | Xcode 26 / Swift Build (open-source)           | Latest tooling with AI assistance support                             |
| Min Deployment  | macOS 26.0 (Tahoe)                             | Liquid Glass APIs, latest MusicKit, SwiftData                         |

## 3.2 High-Level Module Architecture

The application is structured as a modular monolith with clear dependency boundaries. Six primary modules communicate through well-defined protocols:

- **SkinEngine:** Parses WSZ archives, extracts and caches bitmap sprites, provides a SkinProvider protocol for UI components to request themed assets

- **AudioCore:** Manages the AVAudioEngine graph including playback, EQ, DSP effects, crossfading, and visualization data tap

- **LibraryManager:** Coordinates MusicKit and ITunesLibrary to build a unified catalog with background metadata enrichment

- **StreamBridge:** Abstracts Bandcamp and Apple Music streaming behind a common StreamSource protocol

- **ScrobbleService:** Implements Last.fm Scrobble API 2.0 with offline caching and batch submission

- **ExportEngine:** Handles discovery and duplication of DRM-free purchased music to external volumes

## 3.3 Process Architecture

Amplibre runs as a single-process application with structured concurrency. The audio rendering pipeline runs on a dedicated real-time thread managed by AVAudioEngine. UI updates flow through MainActor. Background tasks for library scanning, scrobbling, and skin parsing use Swift Task groups with cooperative cancellation. The export engine uses a dedicated serial queue to prevent I/O contention during large file copies.

# 4. Skin Engine: WSZ Compatibility Layer

## 4.1 WSZ File Format

A .wsz file is a ZIP archive (renamed extension) containing BMP images, CUR cursor files, and TXT configuration files. The skin engine must handle case-insensitive filename matching, as community skins vary in capitalization. Files may reside at the archive root or within a single subdirectory.

### 4.1.1 Required Bitmap Files

|              |                |                                                                                                                                            |
|--------------|----------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| **Filename** | **Dimensions** | **Purpose**                                                                                                                                |
| main.bmp     | 275×116 px     | Main window background, clutterbar, and visualization area                                                                                 |
| titlebar.bmp | 275×232+ px    | Title bar graphics: active/inactive states, shade mode, close/minimize/shade buttons, and option buttons (A/D toggle, time mode, vis mode) |
| cbuttons.bmp | 136×18 px      | Transport buttons sprite sheet: Previous, Play, Pause, Stop, Next — each in normal and pressed states                                      |
| shufrep.bmp  | 28×124 px      | Shuffle button (on/off × normal/pressed) and Repeat button (on/off × normal/pressed), plus EQ and Playlist toggle buttons                  |
| volume.bmp   | 68×421 px      | 28 frames of volume slider background (varying fill) plus slider thumb in normal and pressed states                                        |
| balance.bmp  | 38×418 px      | Balance slider backgrounds (24 frames) plus thumb states; if absent, derived from volume.bmp                                               |
| posbar.bmp   | 307×10 px      | Position seek bar background plus draggable thumb in normal and pressed states                                                             |
| monoster.bmp | 56×12 px       | Mono/Stereo indicator lights: active and inactive states                                                                                   |
| playpaus.bmp | 11×9 px        | Play/Pause/Stop status indicator LEDs                                                                                                      |
| numbers.bmp  | 99×13 px       | Digit font sprite sheet (0–9, blank, minus) for the time display                                                                           |
| text.bmp     | 155×18 px      | Bitmap font for the scrolling title display (A–Z, 0–9, symbols)                                                                            |
| eqmain.bmp   | 275×116 px     | Equalizer window: background, slider tracks, preamp, on/off and auto buttons, preset button                                                |
| eq_ex.bmp    | 275×116 px     | Extended equalizer graphics (shade mode, additional states)                                                                                |
| pledit.bmp   | varies         | Playlist editor: window chrome, scrollbar parts, resize handle                                                                             |

### 4.1.2 Configuration Files

|              |                  |                                                                                       |
|--------------|------------------|---------------------------------------------------------------------------------------|
| **Filename** | **Format**       | **Purpose**                                                                           |
| pledit.txt   | INI format       | Playlist color definitions: Normal, Current, NormalBG, SelectedBG, Font name and size |
| viscolor.txt | 24 RGB triplets  | Spectrum analyzer and oscilloscope bar colors (24 rows, one per bar height level)     |
| region.txt   | INI polygon data | Optional non-rectangular window clipping regions for shaped skins                     |

## 4.2 Skin Parser Implementation

The skin parser (SkinArchiveParser) handles the complete ingestion pipeline:

- **Archive Extraction:** Use Foundation’s built-in ZIP support (or a lightweight library like ZIPFoundation) to extract the WSZ. Handle case-insensitive filename resolution since community skins are inconsistent with casing

- **BMP Decoding:** Parse Windows BMP format directly (many skins use unusual bit depths including 8-bit indexed color, 16-bit, 24-bit, and 32-bit). CoreGraphics cannot reliably parse all BMP variants — implement a custom BMP reader that handles BI_RGB, BI_RLE8, and BI_BITFIELDS compression modes

- **Sprite Extraction:** Slice each BMP into individual UI elements using the documented pixel coordinates from the Winamp skin specification. Cache as CGImage instances keyed by element ID and state

- **Transparency:** The first pixel (0,0) of each BMP defines the transparent color. Replace all matching pixels with alpha transparency during extraction

- **Font Parsing:** Extract text.bmp into a character map (A–Z, 0–9, and symbols) and numbers.bmp into digit sprites for the time display

- **Color Configuration:** Parse pledit.txt for playlist colors and viscolor.txt for visualization palette

## 4.3 Skin Rendering Pipeline

The skin renderer uses a hybrid AppKit approach. Each Winamp window (Main, EQ, Playlist) is an NSWindow subclass with a custom NSView that composites skin bitmaps at precise pixel positions. The rendering pipeline operates as follows:

- **Base Layer:** Draw the window background BMP (main.bmp, eqmain.bmp, or pledit.bmp chrome pieces)

- **Interactive Elements:** Overlay button sprites based on current state (normal, pressed, active). Each button tracks mouse-down/mouse-up to toggle sprite states

- **Dynamic Content:** Render the scrolling title ticker using the text.bmp font atlas. Render the time display using numbers.bmp digit sprites. Render the spectrum analyzer or oscilloscope in the designated 76×16 pixel area using viscolor.txt colors

- **Scaling:** Support integer scaling (2×, 3×) via CGAffineTransform with nearest-neighbor interpolation to preserve the pixel-art aesthetic. Fractional scaling uses point-filtering to avoid blur

## 4.4 Skin Browser & Download Integration

Amplibre includes a built-in skin browser that connects to the Winamp Skin Museum at skins.webamp.org. The museum hosts over 100,000 classic skins with searchable metadata. Skins are downloaded as WSZ files via HTTPS and stored in ~/Library/Application Support/Amplibre/Skins/. The browser displays thumbnail screenshots (available from the museum’s S3 storage) and supports search by name, category, and visual style. Users can also drag-and-drop WSZ files from Finder to install skins manually.

# 5. Audio Engine & Playback Pipeline

## 5.1 AVAudioEngine Graph

The audio pipeline is built around AVAudioEngine’s node graph architecture:

**Source Node** → **EQ Node** → **DSP Chain** → **Crossfade Mixer** → **Visualization Tap** → **Main Mixer** → **Output**

- **AVAudioPlayerNode (x2):** Dual player nodes enable crossfading between tracks. When a track nears completion, the next track begins on the alternate player with opposing volume ramps

- **AVAudioUnitEQ:** 10-band parametric EQ mapped to the classic Winamp frequency bands: 70, 180, 320, 600, 1K, 3K, 6K, 12K, 14K, and 16K Hz. Also supports the ISO standard bands (31.5 Hz through 16K Hz)

- **AVAudioMixerNode:** Master volume and balance control. Balance maps to left/right channel gain adjustment

- **Visualization Tap:** An installTap(onBus:) on the mixer output provides real-time PCM sample data to the visualization engine for FFT analysis and waveform display

## 5.2 Supported Formats

Amplibre supports all formats handled by AVAudioEngine natively, plus extended format support through Apple’s audio codecs:

|                    |                |                                                      |
|--------------------|----------------|------------------------------------------------------|
| **Format**         | **Extension**  | **Notes**                                            |
| MPEG Audio Layer 3 | .mp3           | Most common legacy format; full ID3v1/v2 tag support |
| AAC / ALAC         | .m4a, .aac     | Apple’s preferred formats; purchased iTunes music    |
| FLAC               | .flac          | Lossless; widely used by audiophiles and Bandcamp    |
| WAV / AIFF         | .wav, .aiff    | Uncompressed reference formats                       |
| Ogg Vorbis         | .ogg           | Open-source lossy; common on Bandcamp                |
| Opus               | .opus          | Modern efficient codec                               |
| Apple Music (DRM)  | streaming only | Played via MusicKit; cannot be exported              |

## 5.3 Crossfade Implementation

Crossfading uses the dual-player architecture. A configurable overlap duration (0–12 seconds, default 3) triggers preloading of the next track. At the crossfade point, the outgoing player’s volume ramps linearly to zero while the incoming player ramps from zero to the master volume. An equal-power crossfade curve (using sine interpolation) prevents the perceived volume dip that linear crossfading produces.

## 5.4 Replay Gain

Amplibre reads Replay Gain tags from ID3v2 (TXXX:REPLAYGAIN_TRACK_GAIN), Vorbis Comments, and iTunes Sound Check metadata. Users can choose between track-based and album-based gain modes, with an optional limiter to prevent clipping. When no RG data is available, the app can optionally perform on-the-fly loudness analysis using Accelerate.framework’s vDSP for EBU R128 measurement.

# 6. Music Discovery: MusicKit & ITunesLibrary

## 6.1 ITunesLibrary Framework

The ITunesLibrary framework provides direct, read-only access to the user’s Music.app library on macOS. It exposes ITLibrary as the root object, giving access to all media items (ITLibMediaItem) including purchased tracks, imported CDs, and locally added files. Critical metadata available includes:

- **File Location:** The on-disk URL for DRM-free tracks, essential for the backup/export feature

- **Purchase Status:** Whether the track was purchased from the iTunes Store (useful for filtering exportable content)

- **Metadata:** Title, artist, album, genre, year, track number, disc number, artwork, play count, rating, date added, and date last played

- **Playlist Membership:** All playlists (ITLibPlaylist) the track belongs to, including smart playlists

## 6.2 MusicKit Framework

MusicKit provides access to the Apple Music catalog and the user’s cloud library, including music added from Apple Music subscriptions. MusicKit handles authorization (MusicAuthorization.request()) and provides typed, async Swift APIs:

- **MusicLibraryRequest:** Queries the user’s library for songs, albums, artists, and playlists. Supports filtering and sorting

- **MusicCatalogSearchRequest:** Searches the broader Apple Music catalog for discovery

- **MusicSubscription:** Checks whether the user has an active Apple Music subscription to enable streaming features

- **ApplicationMusicPlayer:** The system-managed player for Apple Music content with DRM support

## 6.3 Unified Library Model

Amplibre merges both data sources into a single LibraryItem model. Each item tracks its provenance (local file, iTunes purchase, Apple Music cloud) and capabilities (playable offline, exportable, streamable). A background reconciliation process runs on launch and periodically to detect new additions, removals, and metadata changes.

# 7. Library Backup & External Volume Export

## 7.1 Design Philosophy

This feature addresses a genuine user concern: purchased digital music becoming inaccessible if a user leaves the Apple ecosystem or if DRM policies change. Amplibre provides a straightforward, automated way to maintain a personal backup of all owned, DRM-free music on external storage.

## 7.2 Exportable Content Discovery

The export engine uses ITunesLibrary to enumerate all media items and classifies each as exportable or non-exportable:

|                                             |                 |                                            |
|---------------------------------------------|-----------------|--------------------------------------------|
| **Content Type**                            | **Exportable?** | **Reason**                                 |
| iTunes Store Purchase (DRM-free since 2009) | Yes             | Local AAC/M4A file with no FairPlay DRM    |
| Matched/Upgraded via iTunes Match           | Yes             | 256kbps AAC, DRM-free                      |
| Imported from CD                            | Yes             | User-owned rip, no DRM                     |
| Manually added local files                  | Yes             | User’s own files, no restrictions          |
| Apple Music streaming additions             | No              | FairPlay DRM, requires active subscription |
| Apple Music downloads (offline cache)       | No              | FairPlay DRM, expires with subscription    |

## 7.3 Export Pipeline

The export process follows a carefully designed pipeline:

- **Volume Selection:** User selects a target external volume via an NSOpenPanel restricted to mounted volumes. The app verifies write permissions and available space

- **Manifest Generation:** Scan the library and build a manifest of exportable tracks. Compare against any previous export manifest on the target volume to identify new, modified, and deleted tracks

- **Directory Structure:** Files are organized as: /Amplibre Backup/Artist/Album/## - Title.ext, preserving the original file format and quality

- **File Copy:** Uses FileManager.copyItem with progress reporting via a Progress object. Large libraries use batched sequential I/O to prevent USB bus saturation

- **Metadata Preservation:** Extended attributes store the original iTunes metadata as a JSON sidecar (.amplibre-meta.json) alongside each file, preserving play counts, ratings, and playlists

- **Verification:** Post-copy checksum verification (SHA-256) ensures bit-perfect copies. A summary report details success/failure counts and any skipped DRM content

- **Incremental Sync:** Subsequent exports only copy new or modified tracks, using the manifest to diff. Deleted tracks can optionally be removed from the backup

## 7.4 Scheduling

Users can configure automatic backup on a schedule (daily, weekly, monthly) or on external volume connection. The app registers for NSWorkspace disk mount notifications and triggers an incremental sync when the designated backup volume appears.

# 8. Streaming Integration: Bandcamp & Apple Music

## 8.1 Bandcamp Integration

Bandcamp offers an OAuth 2.0 API designed for labels and partners. Amplibre integrates with Bandcamp to enable streaming of purchased music from the user’s Bandcamp collection. The integration flow:

- **Authentication:** OAuth 2.0 client credentials flow. The user authorizes Amplibre via a web-based OAuth consent screen opened in the system browser (ASWebAuthenticationSession). Access tokens expire hourly and are refreshed automatically using the stored refresh token

- **Collection Sync:** Fetch the user’s purchased albums and tracks via the Bandcamp API. Display them in the Amplibre library with Bandcamp branding

- **Streaming Playback:** Stream tracks using the streaming URLs provided by the API. Audio is played through AVAudioEngine’s URL-based player node with buffering for smooth playback

- **Download for Offline:** Where the user’s Bandcamp purchase includes download rights, offer high-quality download (FLAC/320kbps MP3) for offline playback and export

## 8.2 Apple Music Integration

Apple Music streaming is handled entirely through MusicKit’s ApplicationMusicPlayer, which manages DRM decryption and playback transparently. Amplibre wraps this in a StreamSource conforming adapter:

- **Catalog Search:** MusicCatalogSearchRequest enables discovery of the full Apple Music catalog from within Amplibre

- **Library Playback:** Tracks in the user’s Apple Music library play through ApplicationMusicPlayer. The skin-rendered transport controls (play, pause, seek) send commands to the player

- **Now Playing:** MusicKit publishes now-playing state through its Queue property, which Amplibre observes to update the title ticker, time display, and visualization

- **Limitations:** Apple Music content cannot be routed through the AVAudioEngine DSP chain for EQ or visualization. Amplibre displays a tasteful notification when EQ is unavailable for DRM content and falls back to the system EQ (if available)

## 8.3 Unified StreamSource Protocol

Both streaming backends conform to a common protocol:

protocol StreamSource { func search(query: String) async throws -\> \[StreamTrack\] func play(track: StreamTrack) async throws func pause() func resume() var nowPlaying: AsyncStream\<NowPlayingInfo\> { get } var canApplyDSP: Bool { get } }

# 9. Last.fm Scrobbling Service

## 9.1 API Integration

Amplibre implements the Last.fm Scrobble API 2.0 for recording listening history. The integration consists of two endpoints:

- **track.updateNowPlaying:** Called when a track begins playing. Sends artist, track, album, duration, and album artist to update the user’s Now Playing status on their Last.fm profile

- **track.scrobble:** Called when a track meets the scrobble criteria: the track is longer than 30 seconds, and the user has listened to at least half the track or 4 minutes (whichever comes first). Supports batch submission of up to 50 scrobbles per request

## 9.2 Authentication

Last.fm uses a session key authentication flow. Amplibre obtains authorization by redirecting the user to Last.fm’s auth page, receiving a token callback, then exchanging it for a persistent session key stored in the macOS Keychain. The session key does not expire unless explicitly revoked. All API calls are signed with an MD5 hash of the method parameters plus the API secret, per Last.fm’s authentication specification.

## 9.3 Offline Caching

When network connectivity is unavailable, scrobbles are queued in a local SQLite database (via SwiftData). The queue is processed whenever connectivity returns, with exponential backoff for server errors (codes 11 and 16). The cache persists across app restarts, ensuring no listening data is lost. Last.fm’s 2-week submission window is respected — scrobbles older than 14 days are silently discarded from the cache.

## 9.4 Scrobble Sources

Scrobbling works for all playback sources:

- **Local Files:** Full metadata from ID3/Vorbis tags

- **Apple Music:** Metadata from MusicKit’s NowPlaying info

- **Bandcamp:** Artist, track, and album from the Bandcamp API response

# 10. UI Architecture: Windows & Docking

## 10.1 Window System

Amplibre recreates Winamp’s multi-window paradigm using custom NSWindow subclasses. Each logical component (Main, Equalizer, Playlist, Library) is a borderless, non-resizable (except Playlist height), always-on-top window with custom chrome rendered from the active skin’s bitmaps.

- **WinampMainWindow:** 275×116 px base size (scaled). Contains transport controls, position bar, volume, balance, title ticker, time display, visualization area, and clutterbar options

- **WinampEQWindow:** 275×116 px. Ten EQ sliders, preamp, on/off toggle, auto-load toggle, presets button, and EQ graph

- **WinampPlaylistWindow:** 275×(variable) px. Resizable vertically. Track list, scrollbar, add/remove/select/misc buttons, and time totals

- **WinampLibraryWindow:** SwiftUI-based modern panel for library browsing, search, and streaming catalog. Uses Liquid Glass material when undocked for native Tahoe integration

## 10.2 Magnetic Docking

Windows snap together when dragged within a configurable pixel threshold (default: 10px), replicating Winamp’s iconic docking behavior. When docked, windows move together as a group. The docking engine calculates edge proximity between all visible windows and the screen edges. Docked groups maintain their relative positions during drag operations. Double-clicking the title bar toggles Window Shade mode, which collapses each window to a thin strip using the shade-mode graphics from titlebar.bmp.

## 10.3 AppKit + SwiftUI Hybrid

The skin-rendered windows use AppKit (NSWindow/NSView) for pixel-precise bitmap compositing. The Library/Browser panel, Preferences, and Skin Browser use SwiftUI with macOS 26’s Liquid Glass materials for a modern feel. Communication between the two layers uses Combine publishers and @Observable models. The SwiftUI components are hosted in separate NSWindows that participate in the docking system via the same magnetic docking engine.

# 11. Equalizer & DSP Pipeline

## 11.1 10-Band Graphic Equalizer

Amplibre’s equalizer maps to the classic Winamp frequency bands using AVAudioUnitEQ with 10 parametric bands. Each band has a configurable gain range of +/-12 dB with a preamp providing an additional +/-20 dB. The EQ node sits between the player node and the main mixer in the AVAudioEngine graph.

|          |                 |              |                   |
|----------|-----------------|--------------|-------------------|
| **Band** | **Winamp Freq** | **ISO Freq** | **Bandwidth (Q)** |
| 1        | 70 Hz           | 31.5 Hz      | 1.0               |
| 2        | 180 Hz          | 63 Hz        | 1.0               |
| 3        | 320 Hz          | 125 Hz       | 1.0               |
| 4        | 600 Hz          | 250 Hz       | 1.0               |
| 5        | 1,000 Hz        | 500 Hz       | 1.0               |
| 6        | 3,000 Hz        | 1,000 Hz     | 1.0               |
| 7        | 6,000 Hz        | 2,000 Hz     | 1.0               |
| 8        | 12,000 Hz       | 4,000 Hz     | 1.0               |
| 9        | 14,000 Hz       | 8,000 Hz     | 1.0               |
| 10       | 16,000 Hz       | 16,000 Hz    | 1.0               |

## 11.2 EQ Presets

Amplibre ships with all 18 original Winamp presets (Classical, Club, Dance, Flat, Full Bass, Full Bass & Treble, Full Treble, Laptop Speakers, Large Hall, Live, Party, Pop, Reggae, Rock, Ska, Soft, Soft Rock, Techno). Users can create, save, import, and export custom presets. Winamp .eqf preset files are supported for import, parsed using the documented binary format. Auto-load presets associate specific EQ settings with individual tracks by filename hash.

## 11.3 DSP Extensions

The audio pipeline supports inserting additional AVAudioUnit nodes for DSP effects. An Audio Unit hosting framework allows loading third-party AU v3 plugins. Amplibre ships with built-in reverb (AVAudioUnitReverb) and time-stretch (AVAudioUnitTimePitch) effects accessible from a modern SwiftUI panel.

# 12. Visualization Engine

## 12.1 Built-in Visualizations

The Winamp main window has a 76×16 pixel visualization area that displays either a spectrum analyzer or oscilloscope. Amplibre replicates both using real-time audio data from the AVAudioEngine mixer tap:

- **Spectrum Analyzer:** 512-point FFT via Accelerate.framework’s vDSP_DFT. The result is binned into 76 frequency bands (matching the pixel width), with logarithmic frequency scaling. Bar heights are drawn using the 24-color palette from viscolor.txt, with peak indicators that decay over time

- **Oscilloscope:** Direct PCM waveform rendering, downsampled to 76 points. The waveform is centered vertically in the 16-pixel display area and drawn using the skin’s primary visualization color

## 12.2 Extended Visualization (Metal)

Beyond the classic 76×16 area, Amplibre offers a full-window Metal-based visualization mode inspired by MilkDrop. A dedicated MTKView renders shader-based effects driven by audio frequency data. The visualization framework supports loading community-created shader presets (converted from Butterchurn/MilkDrop format to Metal shading language). This window participates in the docking system and can be detached as a standalone floating or fullscreen display.

# 13. Plugin Architecture

Amplibre defines a lightweight plugin protocol system to support extensibility in key areas:

- **Input Plugins:** Conform to AudioInputPlugin protocol to add support for additional file formats. Receives a URL, returns an AVAudioPCMBuffer stream

- **Output Plugins:** Conform to AudioOutputPlugin to route audio to alternative destinations (AirPlay groups, network streaming endpoints)

- **Visualization Plugins:** Conform to VisualizationPlugin, receiving an AudioSpectrumData struct (FFT magnitudes + PCM samples) per frame and rendering to a CALayer or MTLTexture

- **General Plugins:** Conform to GeneralPlugin for miscellaneous features (Discord Rich Presence, global hotkeys, sleep timer, alarm clock)

Plugins are loaded from ~/Library/Application Support/Amplibre/Plugins/ as dynamic frameworks (.framework bundles) with a standardized Info.plist declaring the plugin type and entry point class name.

# 14. Data Model & Persistence

## 14.1 SwiftData Models

Amplibre uses SwiftData (macOS 26) for its persistent data layer:

- **LibraryItem:** Unified track representation: title, artist, album, duration, fileURL (optional), provenance (local/purchased/appleMusic/bandcamp), playCount, rating, dateAdded, dateLastPlayed, replayGainTrack, replayGainAlbum

- **Playlist:** Name, ordered array of LibraryItem references, smart playlist query (optional), source (local/iTunes/AppleMusic)

- **EQPreset:** Name, preamp gain, 10-band gain values, isAutoLoad flag, associated file hash (for auto-load)

- **SkinMetadata:** Name, filePath, md5Hash, lastUsed date, downloadURL (for museum skins)

- **ScrobbleCache:** Artist, track, album, timestamp, submitted flag, retryCount

- **ExportManifest:** VolumeUUID, lastSyncDate, array of ExportedTrack (sourceHash, destinationPath, copyDate)

## 14.2 Keychain Storage

Sensitive credentials are stored in the macOS Keychain using Security.framework:

- **Last.fm Session Key:** Persistent authentication token for scrobbling

- **Bandcamp OAuth Tokens:** Access token and refresh token pair

- **Apple Music Token:** Managed by MusicKit internally, but subscription status is cached

# 15. Build Configuration & Deployment

## 15.1 Xcode 26 Project Structure

|                 |               |                                                    |
|-----------------|---------------|----------------------------------------------------|
| **Target**      | **Type**      | **Description**                                    |
| Amplibre        | Application   | Main macOS app bundle                              |
| AmplibreCore    | Framework     | Shared audio engine, skin parser, data models      |
| AmplibreUI      | Framework     | SwiftUI views, skin renderer, visualization engine |
| AmplibreTests   | XCTest Bundle | Unit and integration tests                         |
| AmplibreUITests | XCTest Bundle | UI automation tests                                |

## 15.2 Entitlements & Capabilities

- **com.apple.security.app-sandbox:** Sandboxed with specific exceptions

- **com.apple.security.files.user-selected.read-write:** Access to user-selected external volumes for backup

- **com.apple.security.files.downloads.read-write:** Access to Downloads for skin file installation

- **com.apple.security.network.client:** Outbound networking for Last.fm, Bandcamp, Apple Music, and skin downloads

- **com.apple.security.personal-information.photos-library:** Not needed (we use MusicKit, not PhotoKit)

- **com.apple.developer.music-kit:** MusicKit entitlement for Apple Music integration

## 15.3 Distribution

Amplibre is distributed via the Mac App Store and as a notarized direct download DMG. The App Store version uses the standard sandbox profile. The direct download version includes the hardened runtime with the audio-input entitlement for future microphone-based features (karaoke mode). Both builds are signed with a Developer ID certificate and notarized via Apple’s notary service.

# 16. Security & Privacy

- **User Authorization:** MusicKit authorization is requested once via the standard system prompt. Users can revoke access in System Settings \> Privacy & Security \> Media & Apple Music

- **Credential Storage:** All OAuth tokens and session keys use Keychain Services with kSecAttrAccessibleWhenUnlockedThisDeviceOnly protection class

- **Skin File Safety:** WSZ files are validated before extraction: archive size limits (50MB max), no path traversal in filenames, no executable content. BMP files are parsed in a sandboxed context

- **Network Security:** All API communication uses TLS 1.3. Certificate pinning is applied for Last.fm and Bandcamp API endpoints. App Transport Security exceptions are not required

- **Export Integrity:** Exported files are verified with SHA-256 checksums. The export manifest is signed with a local key to detect tampering

- **Privacy:** No telemetry or analytics. Listening data is only sent to Last.fm if the user explicitly enables scrobbling. No data is sent to Amplibre servers (there are none)

# 17. Testing Strategy

|                   |                        |                                                                                                                       |
|-------------------|------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **Test Layer**    | **Framework**          | **Coverage Targets**                                                                                                  |
| Unit Tests        | XCTest + Swift Testing | Skin parser (BMP decoding, sprite extraction), EQ preset serialization, scrobble queue logic, export manifest diffing |
| Integration Tests | XCTest                 | MusicKit library sync, AVAudioEngine pipeline setup, Last.fm API round-trip with test account                         |
| Snapshot Tests    | Swift Snapshot Testing | Skin rendering accuracy: compare rendered output of 100 reference skins against Webamp screenshots pixel-by-pixel     |
| UI Tests          | XCUITest               | Window docking behavior, skin switching, playlist management, settings persistence                                    |
| Performance Tests | XCTest measureBlock    | Skin loading time (\<200ms), FFT visualization frame rate (\>30fps), library scan throughput                          |
| Fuzz Testing      | LibFuzzer integration  | WSZ parser against malformed archives, BMP parser against corrupted images                                            |

# 18. Appendix: WSZ Bitmap Specification

This appendix provides the complete pixel coordinate mapping for the main window skin elements, enabling precise sprite extraction from each BMP file.

## 18.1 main.bmp (275×116)

|                |       |       |           |            |                                                |
|----------------|-------|-------|-----------|------------|------------------------------------------------|
| **Region**     | **X** | **Y** | **Width** | **Height** | **Description**                                |
| Background     | 0     | 0     | 275       | 116        | Full window background                         |
| Title Bar Area | 0     | 0     | 275       | 14         | Space for titlebar.bmp overlay                 |
| Clutterbar     | 10    | 22    | 8         | 43         | Options buttons (O/A/I/D/V)                    |
| Visualization  | 24    | 43    | 76        | 16         | Spectrum analyzer or oscilloscope display area |
| Time Display   | 48    | 26    | 63        | 13         | LED digit time readout area                    |
| Kbps Display   | 111   | 43    | 15        | 6          | Bitrate text display                           |
| KHz Display    | 156   | 43    | 10        | 6          | Sample rate text display                       |
| Mono/Stereo    | 212   | 41    | 56        | 12         | Mono/Stereo indicator area                     |
| Title Ticker   | 111   | 24    | 153       | 6          | Scrolling song title area                      |
| Volume Pos     | 107   | 57    | 68        | 13         | Volume slider region                           |
| Balance Pos    | 177   | 57    | 38        | 13         | Balance slider region                          |
| Position Bar   | 16    | 72    | 248       | 10         | Seek position bar region                       |
| Transport Btns | 16    | 88    | 114       | 18         | Prev/Play/Pause/Stop/Next buttons              |
| EQ Toggle      | 219   | 58    | 23        | 12         | Equalizer window toggle button                 |
| PL Toggle      | 242   | 58    | 23        | 12         | Playlist window toggle button                  |
| Shuffle        | 164   | 89    | 46        | 15         | Shuffle button                                 |
| Repeat         | 210   | 89    | 28        | 15         | Repeat button                                  |

## 18.2 cbuttons.bmp Transport Button Sprites

|            |              |              |               |               |           |            |
|------------|--------------|--------------|---------------|---------------|-----------|------------|
| **Button** | **Normal X** | **Normal Y** | **Pressed X** | **Pressed Y** | **Width** | **Height** |
| Previous   | 0            | 0            | 0             | 18            | 23        | 18         |
| Play       | 23           | 0            | 23            | 18            | 23        | 18         |
| Pause      | 46           | 0            | 46            | 18            | 23        | 18         |
| Stop       | 69           | 0            | 69            | 18            | 23        | 18         |
| Next       | 92           | 0            | 92            | 18            | 22        | 18         |
| Eject      | 114          | 0            | 114           | 18            | 22        | 16         |

## 18.3 numbers.bmp Digit Sprites

The numbers.bmp file is 99×13 pixels containing 11 characters, each 9 pixels wide. Characters are arranged left to right: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, blank. The minus sign for remaining-time display is derived from the middle row of the digit 8.

## 18.4 text.bmp Font Atlas

The text.bmp file is 155×18 pixels containing the bitmap font used for the scrolling title ticker. Characters are 5 pixels wide on a grid. Row 1 contains A–Z, Row 2 contains punctuation and special characters, Row 3 contains 0–9 and additional symbols. The first pixel of the image defines the transparent color.

**End of Document**

Amplibre Architecture Document v1.0 — April 2026. This document describes the planned architecture and is subject to revision during implementation.
