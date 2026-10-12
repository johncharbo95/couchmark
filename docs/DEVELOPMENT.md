# Developing Couchmark

This guide is for anyone changing the code. No prior Roku experience is assumed.

## Setup

1. Put your Roku in **developer mode** (see the README's install section) and note its IP and password.
2. Install [VS Code](https://code.visualstudio.com/) and the **BrightScript Language** extension (`RokuCommunity.brightscript`). VS Code suggests it when you open this folder.
3. Copy `.env.example` to `.env` and fill in `ROKU_HOST` and `ROKU_PASSWORD`. `.env` is git-ignored; never commit credentials.
4. Press **F5** (launch config *"Couchmark: deploy & debug on Roku"*). The extension zips the app, sideloads it, and attaches the debugger. `print` output appears in the Debug Console.

### Linting and tests

The extension lints as you type using `bsconfig.json`. From a terminal (requires Node.js), run `npm install` once, then:

```sh
npm run lint     # brighterscript: syntax, unknown functions, reserved words
npm test         # unit tests, run on your computer (no Roku needed)
npm run check    # both
```

Run `npm run check` before every commit. Build output goes to `out/`, which is git-ignored. See [Testing](#testing) for how the tests work.

### Placeholder artwork

`tools/make-placeholder-images.ps1` regenerates the icons, splash screens and spinner in `images/`. To use real artwork, replace the PNGs and keep the same pixel sizes:

| File | Size |
|---|---|
| `icon_focus_fhd.png` | 540 × 405 |
| `icon_focus_hd.png` | 290 × 218 |
| `icon_focus_sd.png` | 246 × 140 |
| `splash_fhd.png` / `_hd` / `_sd` | 1920×1080 / 1280×720 / 720×480 |
| `spinner.png` | 96 × 96, transparent |

## BrightScript and SceneGraph in five minutes

- **`source/main.brs`** runs first, on the *main thread*. It creates the screen and the root component, then waits for events. It contains no UI logic.
- **Components** (`components/*.xml` and `.brs`) are UI nodes, like HTML elements with a script attached. The XML declares the `<interface>` (public fields) and `<children>` (child nodes). The `.brs` file has `init()` and event handlers. Components run on the *render thread*.
- **`m`** is the component's private state. **`m.top`** is the component node itself (its interface fields). **`m.global`** is a node shared by every component.
- **Observers:** `node.ObserveField("field", "handlerName")` calls the handler when the field changes. Most communication between components uses observers.
- **Task nodes** run a function on a background thread. Anything slow, such as reading the USB drive or parsing files, must be in a Task, or the UI freezes and Roku may kill the app. You start a task with `task.control = "run"` and observe its output field.
- **Focus:** only the focused node receives remote keys. Unhandled keys go to `onKeyEvent()` in each parent in turn, up to the scene.
- **Script includes:** a component can only call functions from scripts it lists in `<script uri="…"/>`. Shared helpers live in `components/lib/` and are included where needed.

Official references: [SceneGraph](https://developer.roku.com/docs/developer-program/core-concepts/core-concepts.md) · [BrightScript language](https://developer.roku.com/docs/references/brightscript/language/brightscript-language-reference.md) · [Node reference](https://developer.roku.com/docs/references/scenegraph/node.md)

## Project layout

```
manifest                  App name, version, icons, resolution (fhd)
source/main.brs           Entry point + USB plug/unplug events
components/
  MainScene.xml/.brs      Root scene: screen stack, USB scanning, Back key
  screens/                Full-screen pages (all extend BaseScreen)
    BaseScreen.xml        Declares the "navigate" field
    HomeScreen            Netflix-style home: hero + rows (Continue Watching, Shows, Movies, Browse)
    MovieScreen           A movie's page: Resume / Play from beginning
    ShowScreen            A show's page: Continue button, seasons | episodes
    FolderListScreen      A–Z lists of all movies or shows; the Other folder browser
    SlideshowScreen       Dated photo/video slideshow with preloading and transitions
    SettingsScreen        Photo duration, transition, speed, clear history, version
    ResumeDialog          "Resume from … / Start over" (episodes)
    PlayerScreen          Video playback with custom controls; saves progress
    MessageScreen         Title + explanation (errors, help, placeholders)
  tasks/                  Background work (Task nodes)
    UsbScanTask           Finds ext*: volumes and their Movies/Shows/Other folders
    HomeScanTask          Home rows: library + artwork, Continue Watching tiles
    FolderScanTask        Lists subfolders or video files (+ a movie's artwork)
    ShowScanTask          Reads one show's seasons + episodes (+ artwork)
    MediaDateTask         Lists a folder's photos/videos and sorts them by date taken
  widgets/                Reusable pieces
    MediaTile             16:9 tile with artwork, progress bar, ✓ (RowList item)
    ListItem              List row with title, detail text, badge (MarkupList item)
    LoadingOverlay        Dimmed background + spinner while a Task runs
    UpNextOverlay         "Up next" card with a 10 s countdown
  lib/                    Plain BrightScript helpers included via <script>
    Scan.brs              Reading folders: ScanFolders, ScanVideos, ScanShow, FindArtwork (Tasks only)
    Library.brs           Movie/show helpers: player items, badges, "Continue" target
    Progress.brs          Registry storage of playback progress + pruning
    Settings.brs          User settings: storage, choices, labels, next/previous value
    Transitions.brs       What each transition does (start/end values per slot)
    MediaDate.brs         Date taken: EXIF, MP4/MOV mvhd (partial reads), file mtime; EXIF orientation
    NaturalSort.brs       Natural sort keys, S01E02 / 1x02 detection
    MediaTypes.brs        Supported extensions, junk-file filter, stream formats
    Format.brs            Time formatting (1:02:14, "23 min")
    Text.brs              Shared user-facing strings
images/                   Icons, splash screens, player icons, fade, ✓ badge
tests/                    Unit tests run off-device with brs (not packaged), see Testing
tools/                    Dev scripts (not packaged)
docs/                     Documentation (not packaged)
```

Only `manifest`, `source/`, `components/` and `images/` are packaged. This is set in both `.vscode/launch.json` and `bsconfig.json`; keep the two lists in sync.

## Architecture

### Navigation (screen stack)

`MainScene` keeps an array of open screens. Screens never create each other directly. Instead, a screen asks MainScene to do it:

```brightscript
m.top.navigate = { screen: "MessageScreen", fields: { title: "Hello", message: "…" } }
m.top.navigate = { screen: "PlayerScreen", fields: {...}, replace: true }  ' close me first
m.top.navigate = { action: "back" }     ' close me
m.top.navigate = { action: "rescan" }   ' rescan USB drives
```

MainScene creates the node, applies `fields` with `SetFields`, hides the previous screen, and focuses the new one. `replace` is used by ResumeDialog so Back from the player returns to the show page, not the dialog. **Back** pops the top screen. On the home screen, Back is left unhandled so Roku exits the app.

Fields are applied *after* a component's `init()`, so screens start their work (scans, playback) the first time they receive focus. When a screen receives focus, it passes focus on to its list, grid or button. Screens that show progress also watch their own `visible` field and refresh when they reappear after the player closes.

### USB library

`UsbScanTask` lists the volumes from `roFileSystem.GetVolumeList()`, keeps those starting with `ext` (USB drives), and looks for `Movies`, `Shows` and `Other` folders (case-insensitive) at each root. The result is stored in `m.global.library`:

```brightscript
{
    volumes: ["ext1:", "ext2:"],
    roots: {
        movies: ["ext1:/Movies", "ext2:/Movies"],   ' merged across drives
        shows:  ["ext1:/Shows"],
        other:  []
    }
}
```

`main.brs` forwards `roFileSystemEvent`s (drive plugged in or removed) to `MainScene.volumesChanged`. MainScene waits 1.5 s for the drive to mount, rescans, and returns to the home screen.

### Folder scanning and sorting

All drive access lives in `lib/Scan.brs` and runs inside Task nodes:

- `ScanFolders(paths)`: subfolders, merged by name across drives (`paths` keeps every location).
- `ScanVideos(paths, episodeAware)`: playable video files.
- `ScanShow(paths)`: seasons and episodes, flattened into one list of player items plus each season's slice of it (`first`, `count`). Videos directly in the show folder become a season called "Episodes".
- `FindArtwork(paths)`: the first `fanart|landscape|backdrop|poster|folder|cover|thumb` `.jpg/.jpeg/.png` found in the folder.

Junk files (`.*`, `$*`, `Thumbs.db`, …) and unsupported extensions are skipped. Sorting uses `NaturalSortKey()`, which zero-pads every run of digits so a plain alphabetical sort gives "2" before "10". With `episodeAware`, names containing `S01E02` or `1x02` sort by season and episode first.

### Home screen

`HomeScreen` uses a `RowList` of `MediaTile`s and two `HomeScanTask` runs:

1. **`library`** (once): every show and movie folder with its artwork.
2. **`continue`** (every time the home screen reappears): `ProgressListRecent()` returns the saved records, newest first. For each one, the task finds the title's folder again, scans it, and builds a tile with **ready-made PlayerScreen fields**. That's why one OK press starts playback with no further scanning. Movies are included if they have a resume point. Shows are included if `ContinueTarget()` finds something to watch. The row holds at most 12 tiles.

Each tile's `action` field says what OK does (`play`, `show`, `movie` or `browse`). The hero area at the top shows the focused tile's title, subtitle and artwork, faded into the background with `images/fade.png`. When rows are rebuilt, the focus is restored by row key and column.

### Movie and show pages

**MovieScreen** lists the movie's parts and offers *Resume* + *Play from beginning*, or just *Play*.

**ShowScreen** has three focus areas: the Continue button, the season list (left) and the episode list (right). Lists don't handle a key they can't use (for example Up on the first row), so the key reaches `ShowScreen.onKeyEvent`, which moves to another area. Highlighting a season refills the episode list. The Continue button text comes from `ContinueTarget()` in `Library.brs`:

- The last-played episode has a resume point → **Continue S02E05 at 23:14**
- The last-played episode was finished → **Next: S02E06**
- It was played but stopped within 15 s → **Continue S02E06**
- The show was never played, or the last-played episode is gone → **Start watching S01E01**, or **Next:** the first unwatched episode
- Everything has been watched → no button

OK on an episode with a resume point opens ResumeDialog. "Start over" restarts *that* episode (`restartIndex`).

### The player

`PlayerScreen` gets a list of **items** (`{ url, label, id }`) and a `kind`:

- **movie:** the items are the movie's parts.
- **show:** the items are *every* episode of the show in watching order, so "Up next" and the Next button carry on into the next season.

The Video node's own UI is disabled (`enableUI="false"`), and the screen itself keeps focus rather than the Video node, so every key reaches `PlayerScreen.onKeyEvent`. The overlay has a title, a progress bar ("scrubber") and a button row that's built at runtime. Previous and Next only appear when there is more than one item. Focus is either on the bar (Left/Right seek 10 s) or on the buttons (Left/Right move). ↺ (`replay`) seeks −10 s and ◀◀/▶▶ (`rewind`/`fastforward`) seek ±30 s. Repeated seeks add up: each one starts from the previous target (`m.pendingSeek`), not from the playback position, which lags behind. A Timer hides the controls after 3 s unless playback is paused.

When an item finishes and another follows, UpNextOverlay counts down 10 s. After the last item, the player closes. Playback errors (usually an unsupported codec) replace the player with a MessageScreen that shows the Video node's `errorMsg`.

Progress is saved every 10 s, on Back, and before Previous/Next. The rules differ slightly by kind:

| | Movie | Episode |
|---|---|---|
| Past 90% (or finished) | last part: watched ✓, resume point cleared; earlier part: resume at the next part | watched ✓, resume point cleared |
| 15 s or more, under 90% | resume point saved (part + position) | resume point saved, becomes "last played" |
| Under 15 s | nothing saved (an old resume point on part 1 is cleared) | becomes "last played", no resume point |

### Other folders and slideshows

**Browsing:** FolderListScreen with `kind: "other"` runs FolderScanTask in `"browse"` mode. That returns the subfolders, plus counts of the photos, videos and unsupported files directly in the folder (`ScanMedia()`). If there are any photos or videos, a **Play slideshow** row is inserted first. Other rows open the subfolder in another FolderListScreen.

**Dates (`MediaDateTask` + `lib/MediaDate.brs`):**

- **JPEG:** `roImageMetadata.GetMetadata().datetime` (EXIF date taken). EXIF tag 274 (orientation) gives the rotation.
- **MP4/MOV/M4V:** walk the top-level boxes by reading only each 8–16-byte header with `roByteArray.ReadFile(path, offset, length)` and jumping over the rest, so a large `mdat` is never read. Inside `moov`, read `mvhd`: creation time is seconds since 1904 (UTC), 32-bit in version 0 and 64-bit in version 1. The arithmetic uses `LongInteger` (`&`) because the values exceed 32 bits and Doubles can round when converted back. Offsets past ~2 GB can't be passed to `ReadFile`, so those files fall back to the modified time.
- **Otherwise:** `roFileSystem.Stat(path).mtime`.
- EXIF dates are local time, while MP4 and file times are UTC. The UTC ones are shifted by the TV's time-zone offset so photos and videos interleave correctly.

Items are sorted by a zero-padded date key, with the natural name order as tie-breaker (burst photos).

**Playback (`SlideshowScreen`):** there are two *slots*. Each is a Group (for transitions to animate) holding a Poster (rotated for EXIF orientation). The visible slot is `m.front`. While it shows, `preloadNext()` loads the next photo into the hidden slot. `showItem()` reveals the hidden slot as soon as its `loadStatus` is `ready`, so there's never a black frame. Sideways photos use a 1080×1920 poster turned a quarter-turn around its centre, so after rotation they fill the screen height. Posters decode at screen size (`loadWidth`/`loadHeight`), not camera resolution.

- **Timing:** each photo stays up for `SettingsGet().photoSeconds` (Timer). Pausing remembers the remaining time (`roTimespan`).
- **Videos:** play in a Video node above the slots, and `finished` moves on.
- **Failures:** files that fail to load or play are skipped. If every file fails, a message is shown.
- **Looping:** after the last item, the slideshow starts over at the first.

### Transitions

Each slot is three nodes: **slot** (a Group clipped to the screen with `clippingRect`; moved, scaled and faded) → **inner** (a Group) → **poster**. `TransitionPlan(name, seconds, randomPick)` in `lib/Transitions.brs` returns `[start, end]` values for both slots' opacity, translation, scale and inner translation. It's pure data, so it's unit-tested.

| Effect | Incoming photo | Outgoing photo |
|---|---|---|
| fade | opacity 0 → 1 (on top) | stays |
| slide | from x = 1920 → 0 (on top) | stays |
| push | from x = 1920 → 0 | x 0 → −1920 |
| wipe | slot x −1920 → 0, inner x 1920 → 0: the clip window sweeps in while the picture stays still | stays |
| zoom | scale 0.85 → 1, opacity 0 → 1 | stays |

The old photo never goes away before the new one covers it, so there is no black frame between photos.

`SlideshowScreen` has one `Animation` with eight interpolators (opacity, translation, scale and inner translation for slots A and B). It copies a plan into their `keyValue`s, puts the incoming slot on top, and starts the animation. Only after it ends (`endTransition`) is the old slot hidden, reset and reused to **preload** the next photo; preloading earlier would change the picture that is still sliding out. Skipping ahead mid-transition jumps to the end state first. After a video, or for the first photo, there's nothing to transition from, so the photo fades in over black.

### Settings screen

Rows are ListItems with a `key` field. Left/Right (unused by the vertical list, so they reach `SettingsScreen.onKeyEvent`) call `NextSettingValue()` and save immediately with `SettingsSave()`. The slideshow reads settings when it starts. *Clear watch history* needs OK twice, and moving to another row cancels. It calls `ProgressClearAll()`, and the home screen's Continue Watching row updates when you return.

### Registry schema

Roku gives each app about 16 KB of persistent registry storage. The code for this lives in `components/lib/Progress.brs`.

| Section | Key | Value | Status |
|---|---|---|---|
| `progress` | `m` + 8 hex chars of MD5(lower-case movie folder name) | `lastUsed\|part\|parts\|pos\|dur\|watched\|title` | ✅ |
| `progress` | `s` + 8 hex chars of MD5(lower-case show folder name) | `lastUsed\|lastEp\|watched\|partials\|title` | ✅ |
| `settings` | `dur`, `tr`, `spd` | photo seconds, transition name, speed name | ✅ |

The `title` (folder name) lets the home screen build Continue Watching from the registry alone. It's the last field, so a title containing `|` still parses. Records saved before titles were added have no title. They still work, but they don't appear in Continue Watching until the title is played again.

Movie example: `1760270000|0|1|3734|7200|0|The Matrix` means part 1 of 1, resume at 1:02:14, part length 2:00:00, not yet watched. `part` is 0-based, and `lastUsed` is in seconds since 1970.

Show example: `1760270000|0b12ef|77ac10,0b12ef|c4d2e1:612:2580|The Office`. Here the last episode played is `0b12ef`, two episodes are watched, and `c4d2e1` has a resume point at 10:12 of 43:00. At most 10 resume points are kept per show, most recent first.

An episode id is 6 hex characters of MD5 of the episode's path relative to the show folder (`Season 2/S02E05.mkv`, lower-cased), so adding or renaming *other* files doesn't affect it. When the total size passes about 13 KB, the entries with the oldest `lastUsed` are pruned first.

## Testing

### What is tested, and how

Logic lives in **`components/lib/`** as plain functions. Screens and tasks stay thin: they gather input, call those functions, and show the result. The functions can therefore be tested on a computer with [`brs`](https://github.com/sjbarag/brs), an off-device BrightScript interpreter. Covered so far:

| Test file | What it checks |
|---|---|
| `NaturalSort.test.brs` | "2" before "10", case, `S01E02` / `1x02` codes |
| `MediaTypes.test.brs` | supported/junk files, extensions, episode-name cleanup |
| `Format.test.brs` | `1:02:14`, "23 min" |
| `Progress.test.brs` | registry encoding round trips, titles with `\|`, resume-point limit, newest-first list, pruning to the size budget |
| `Library.test.brs` | `ContinueTarget` cases, badges, movie parts and resume text |
| `MediaDate.test.brs` | MP4/MOV `mvhd` dates on real files (`tests/fixtures/`), fallback to the file date |
| `Transitions.test.brs` | every effect's start/end values, wipe keeps the picture still, random never picks none |
| `Settings.test.brs` | defaults, save/load, damaged values, next/previous with wrap-around, labels |

Screens (focus, layout, playback) need a real Roku and are tested by hand. If you change a screen, also try it on a TV.

### Writing a test

A test file is `tests/<Name>.test.brs`, with a `Main()` that calls the assertions from `tests/lib/Assert.brs` and ends with `finishTests()`:

```brightscript
' @include components/lib/Format.brs
sub Main()
    assertEqual(FormatTime(845), "14:05", "minutes")
    finishTests()
end sub
```

Directives at the top tell `tests/run.js` what to load:

- `' @include path`: app code under test.
- `' @double path`: a *test double*. Functions it defines replace the same-named functions in the included code, but only in the test build; app code doesn't change. Doubles exist for the things that need a Roku:
  - `tests/doubles/Registry.brs`: in-memory registry sections (`progressSection()`, `settingsSection()`), a stand-in for MD5, and a fake clock.
  - `tests/doubles/Files.brs`: file reads from fixtures, a fixed file date, UTC offset 0.
- `' @fixture path`: a file whose bytes become available to the Files double (call `loadFixtures()` first).

Run one file with `npm test -- Progress`.

`tests/bsconfig.json` makes the editor treat `tests/` as its own project. Otherwise it would flag every call into app code as unknown, because those files are only combined by `tests/run.js`.

### Keeping code testable

- Put decisions (what to show, what to save, how to sort or parse) in `components/lib/` functions that take values and return values.
- Touch the device (registry, files, `roDateTime` "now") only through small functions such as `progressSection()`, `settingsSection()`, `md5Hex()`, `nowSeconds()`, `readBytes()`, `fileSizeOf()` and `FileModifiedTime()`. Then a double can replace them.
- A bug fix should come with a test that fails without the fix. Example: `MediaTypes.test.brs` covers the dotted episode names that once showed as "…".

### `brs` quirks

`brs` is not a Roku, so a few things differ. Avoid them in tests, or keep the code neutral:

- No `roRegistrySection`, `roEVPDigest`/`roByteArray.FromAsciiString` or `roByteArray.ReadFile`. That's why the doubles exist.
- Integer literals of 10+ digits are read as Doubles. Keep test numbers small, or compare values computed by the code.
- `Int()` of a large Double loses precision. The app uses `LongInteger` (`&`) for MP4 times, which is exact on both.
- `Right(s, n)` with `n = Len(s)` returns the wrong result.
- `SortBy` doesn't sort when the sort field is a mixed-case key written in a literal (`{ sortKey: … }`). The app sorts flat items by lower-case field names.
- Keys set with dot notation (`aa.photoSeconds = 5`) are stored in lower case. That happens on a Roku too; lookups ignore case. Compare fields one by one rather than whole objects built that way.

On-device unit tests with [Rooibos](https://github.com/georgejecook/rooibos) would be the next step for testing SceneGraph components themselves.

## Debugging tips

- `print` statements appear in the VS Code Debug Console, or via `telnet <roku-ip> 8085`.
- A crash drops into the BrightScript debugger, which shows the file and line. Type `bt` for a backtrace and `var` for local variables.
- The dev web page at `http://<roku-ip>` has a **Utilities → Screenshot** button.
- To test without a drive, unplug it: the "No USB drive found" screen should appear, and plugging the drive back in should reach the home screen within a few seconds.

## Conventions

- Every `.brs` file starts with a header comment that explains its job. Comments explain *why*, not what.
- UI is laid out for 1920×1080 (`ui_resolutions=fhd`).
- Colours: background `#101418`, card `#1E252D`, focus `#2A3440`, accent `#3D7EFF`, secondary text `#8A96A3`.
- The USB drive is read-only. Never write, rename or delete files on it.
