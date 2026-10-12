# Developing Couchmark

This guide is for anyone changing the code. No prior Roku experience is assumed.

## Setup

1. Put your Roku in **developer mode** (see the README's install section) and note its IP and password.
2. Install [VS Code](https://code.visualstudio.com/) and the **BrightScript Language** extension (`RokuCommunity.brightscript`). VS Code suggests it when you open this folder.
3. Copy `.env.example` to `.env` and fill in `ROKU_HOST` and `ROKU_PASSWORD`. `.env` is git-ignored; never commit credentials.
4. Press **F5** (launch config *"Couchmark: deploy & debug on Roku"*). The extension zips the app, sideloads it, and attaches the debugger. `print` output appears in the Debug Console.

### Linting

The extension lints as you type using `bsconfig.json`. To lint from a terminal (requires Node.js):

```sh
npx brighterscript --project bsconfig.json
```

This also writes a staging copy to `out/`, which is git-ignored.

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
    HomeScreen            Movies / Shows / Other / Settings tiles
    MessageScreen         Title + explanation (errors, help, placeholders)
  tasks/                  Background work (Task nodes)
    UsbScanTask           Finds ext*: volumes and their Movies/Shows/Other folders
  widgets/                Reusable pieces
    HomeTile              One home tile (MarkupGrid item component)
    LoadingOverlay        Dimmed background + spinner while a Task runs
  lib/                    Plain BrightScript helpers included via <script>
    Text.brs              Shared user-facing strings
images/                   Icons, splash screens, spinner
tools/                    Dev scripts (not packaged)
docs/                     Documentation (not packaged)
```

Only `manifest`, `source/`, `components/` and `images/` are packaged. This is set in both `.vscode/launch.json` and `bsconfig.json`; keep the two lists in sync.

## Architecture

### Navigation (screen stack)

`MainScene` keeps an array of open screens. Screens never create each other directly. Instead, a screen asks MainScene to do it:

```brightscript
m.top.navigate = { screen: "MessageScreen", fields: { title: "Hello", message: "…" } }
m.top.navigate = { action: "rescan" }   ' rescan USB drives
```

MainScene creates the node, applies `fields` with `SetFields`, hides the previous screen, and focuses the new one. **Back** pops the top screen. On the first screen, Back is left unhandled so Roku exits the app.

When a screen receives focus, it passes focus on to its main list or grid (see `onFocusedChildChange` in `HomeScreen.brs`). The list remembers its position, so returning to a screen keeps your place.

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

### Planned (later milestones)

- **FolderScanTask:** lists one folder, filters junk files, and natural-sorts. Scanning is lazy: a movie's parts are only listed when you open it.
- **MediaDateTask:** reads slideshow dates from EXIF (`roImageMetadata`), the MP4/MOV `mvhd` box (partial `roByteArray.ReadFile` reads), or the file's mtime.
- **Registry storage:** described below.

### Registry schema (planned for milestones 2–5)

Roku gives each app about 16 KB of persistent registry storage.

| Section | Key | Value |
|---|---|---|
| `settings` | `dur`, `tr`, `spd` | photo seconds, transition name, speed name |
| `progress` | 8 hex chars of MD5(folder name) | movie: `lastUsed\|part\|posSec\|watched` |
| `progress` | 8 hex chars of MD5(show folder) | show: `lastUsed\|lastEpHash\|posSec\|watchedHashes\|partials` |

Episode hashes are 6 hex characters of MD5 of the episode's path relative to the show folder. When the total size passes about 13 KB, the entries with the oldest `lastUsed` are pruned first.

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
