# couchmark
Open-source media player for Roku TVs. Plays movies, shows, and photos from a USB drive, remembers where you stopped, and runs dated photo/video slideshows with custom timing and transitions.

Everything runs on the TV. There is no server, account, or companion app: plug in a USB drive, open Couchmark, and press play.

> **Status:** all phase-1 features are in place (milestones 1–5). Expect rough edges until it has been tested on more Roku models; please report issues.

## Features

| Area | What it does | Status |
|---|---|---|
| USB detection | Finds every attached USB drive and merges their folders into one library. Rescans automatically when a drive is plugged in or removed. | ✅ |
| Home | Netflix-style rows: **Continue Watching** (one click resumes), Shows, Movies, and Browse. Uses folder artwork when available. | ✅ |
| Movies | Movie page with Resume / Play from beginning. Multi-file movies play as parts. Finished movies get a ✓. | ✅ |
| Shows | Show page with seasons and episodes side by side, "Continue S02E05 at 23:14", watched ✓ and partly-watched markers, and "Up next" when an episode ends. | ✅ |
| Player | Netflix-style controls: 10-second skip, instant replay, previous/next episode, progress bar. | ✅ |
| Watched marks | Mark movies, episodes or whole seasons as watched / unwatched with the ✱ button. | ✅ |
| Other | Browse folders and play a slideshow of all photos and videos in a folder, ordered by the date they were taken. | ✅ |
| Transitions | None, fade, slide, push, wipe, zoom, random, at three speeds. The next photo is preloaded, so there's never a black flash. | ✅ |
| Settings | Photo duration, transition type and speed, clear watch history. | ✅ |

## Setting up your USB drive

Create these folders at the **top level** of the drive. You don't need all three.

```
Movies/
  The Matrix (1999)/
    The Matrix.mp4
  Lord of the Rings Extended/
    Part 1.mkv              ← several files = one movie played in order
    Part 2.mkv
    poster.jpg              ← optional artwork (see below)
Shows/
  The Office/
    Season 1/
      S01E01 Pilot.mp4
      S01E02 Diversity Day.mp4
Other/
  Summer 2025/
    IMG_0001.jpg
    VID_0002.mp4
    Day trip/               ← subfolders are fine
```

- **Folder names are the titles** you'll see on the TV.
- Files are sorted **naturally**: "Episode 2" comes before "Episode 10". Episode codes such as `S01E02` or `1x02` are recognised.
- Hidden and system files (`.DS_Store`, `Thumbs.db`, `._*` files) are ignored.
- Folder names are not case-sensitive (`movies` works too).
- Several drives work: if two drives each have a `Movies` folder, you see one combined list.
- Couchmark never writes to your drive.

### Artwork (optional)

Put an image in a movie or show folder and Couchmark uses it for the tile and as the page background. It looks for these names, in this order: `fanart`, `landscape`, `backdrop`, `poster`, `folder`, `cover`, `thumb` (with `.jpg`, `.jpeg` or `.png`; upper/lower case doesn't matter). Wide 16:9 images look best. These are the names that tools such as Kodi, Plex and Jellyfin use, so an existing library usually works as is. Titles without artwork get a coloured card with their name.

### Supported files

| Type | Extensions |
|---|---|
| Video | `.mp4` `.m4v` `.mov` `.mkv` `.ts` `.webm` |
| Photo | `.jpg` `.jpeg` `.png` `.gif` `.bmp` |

Whether a particular video plays depends on its codecs and your Roku model; see [Known limitations](#known-limitations).

## Installing on your Roku (sideloading)

Couchmark isn't in the Roku Channel Store, so you install it in developer mode. This is free and only takes a few minutes.

1. **Enable developer mode.** On the Roku remote, press **Home ×3, Up ×2, Right, Left, Right, Left, Right**. Follow the prompts, choose a developer password, and note the IP address shown. The TV restarts.
2. **Get the app package.** Download `couchmark.zip` from the [Releases](../../releases) page (when available), or build it yourself:
   - **Windows (PowerShell):** `Compress-Archive -Path manifest, source, components, images -DestinationPath couchmark.zip -Force`
   - **macOS / Linux:** `zip -r couchmark.zip manifest source components images`
3. **Upload it.** On a computer on the same network, open `http://<your-roku-ip>` in a browser and log in with user `rokudev` and your developer password. Click **Upload**, choose `couchmark.zip`, then click **Install with zip**.
4. Couchmark opens immediately and appears on the Roku home screen as a dev channel.

Only one sideloaded app can be installed at a time, and installing another replaces it.

## Using Couchmark

### Home

The home screen works like Netflix. Up/Down moves between rows, Left/Right scrolls a row, and the top of the screen describes the highlighted title.

- **Continue Watching:** everything you're partway through, most recent first. Press **OK once** to resume exactly where you stopped, or to start the next episode if you finished one.
- **Shows** and **Movies:** your whole library. A blue bar shows how far you got, and a ✓ means watched (past 90%).
- **Browse:** A–Z lists of all shows and movies, **Other** (slideshows), and **Settings**.

Back on the home screen exits Couchmark.

### Movies

A movie's page offers **Resume** and **Play from beginning** (or just **Play**). If a movie folder holds several video files, they play one after another as parts, and between parts an **Up next** card counts down 10 seconds (OK plays now, Back stops).

### Shows

A show's page has a **Continue** button at the top, seasons on the left, and that season's episodes on the right:

- **Continue S02E05 at 23:14** if you stopped partway through an episode
- **Next: S02E06** if you finished the last one
- **Start watching S01E01** if you've never watched it

Use Left/Right to move between seasons and episodes, and Up to get back to the Continue button. Episodes show ✓ when watched and a blue bar with the time left when partly watched. When an episode ends, **Up next** counts down 10 seconds to the next one, including into the next season.

Episode files are ordered by their `S01E02` / `1x02` code when they have one, otherwise naturally by name. Video files placed directly in a show folder (no season folder) appear under "Episodes".

### Other (slideshows)

Open **Browse → Other** to see the folders inside `Other`. In any folder that contains photos or videos, the first row is **Play slideshow**. It shows how many photos and videos the folder holds, and how many files can't be shown (for example HEIC photos). The slideshow includes the files directly in that folder, not its subfolders.

- Items play **in the order they were taken**: the camera date for JPEG photos, the recording date for MP4/MOV videos, and otherwise the file's modified date.
- Photos stay on screen for 5 seconds and change with a fade (both adjustable in Settings). Videos play to the end. After the last item, the slideshow starts over.
- Portrait phone photos are rotated upright automatically.

| Button | Action |
|---|---|
| **OK** or **Play/Pause** | Pause / resume |
| **Left / ◀◀** | Previous photo or video |
| **Right / ▶▶** | Next photo or video |
| **Up / Down / \*** | Show the date, file name and position (e.g. 12 / 240) |
| **Back** | Leave the slideshow |

### Marking as watched / unwatched

Press **✱** (the star/options button) on:

| Where | What ✱ does |
|---|---|
| A movie (home row, A–Z list, or the movie's page) | Watched ✓ ↔ unwatched. Marking watched clears its resume point. The movie page also has a **Mark as watched** button. |
| A **Continue Watching** tile | "I've already seen this": marks that movie or episode watched, and the row moves on to the next episode. |
| An episode (show page) | Watched ✓ ↔ unwatched |
| A season (show page, left list) | Marks every episode in it watched. If they all are already, marks them all unwatched. |
| The **Continue** button (show page) | Marks that episode watched, so Continue moves on |

A short message confirms each change. Marking episodes watched moves the show's **Continue** forward, never backwards. Marking an earlier season doesn't lose your place in a later one.

### Player controls

| Button | Action |
|---|---|
| **OK** or **Play/Pause** | Pause / resume (shows the controls) |
| **Left / Right** | Back / forward 10 seconds |
| **↺** (instant replay) | Back 10 seconds |
| **◀◀ / ▶▶** | Back / forward 30 seconds (press repeatedly to go further) |
| **Down** | Move to the button row: Previous episode · Back 10 · Play/Pause · Forward 10 · Next episode. Use Left/Right to choose and OK to press. |
| **Up** | Back to the progress bar |
| **Back** | Stop and return. Your position is saved. |

The controls hide after 3 seconds, or stay visible while paused. For movies with several parts, Previous/Next move between parts. Single-file movies have no Previous/Next buttons.

If no drive is found, plug one in. Couchmark notices it automatically, or you can press **OK** to look again.

### Settings

Open **Browse → Settings**. Use Up/Down to choose a setting and Left/Right (or OK) to change it. Changes are saved immediately.

| Setting | Choices |
|---|---|
| Photo duration | 3, 5, 8, 10, 15 or 30 seconds |
| Transition | None, Fade, Slide, Push, Wipe, Zoom, Random |
| Transition speed | Slow (1.5 s), Normal (0.8 s), Fast (0.4 s) |
| Clear watch history | Press OK twice. Forgets all resume points and ✓ marks; your files are not touched. |

## Known limitations

- **No transcoding.** Roku plays files directly, so videos must use codecs your Roku supports (H.264/H.265 video with AAC/AC3 audio in MP4 or MKV is the safest choice). Unsupported files are skipped or show an error instead of crashing.
- **HEIC photos are not supported** (the default iPhone format). Convert them to JPEG, or set the iPhone to *Settings → Camera → Formats → Most Compatible*.
- **Subtitles are ignored** for now.
- **Slideshow dates** come from the photo's EXIF data or the video's MP4/MOV header. Photos edited or exported without EXIF, and MKV/TS/WebM videos, use the file's modified date, which may be when the file was copied rather than when it was taken.
- **Watch history is limited.** Roku gives each app about 16 KB of storage, so Couchmark stores progress compactly and forgets the least recently watched titles when space runs out.
- History is keyed by folder name, so renaming a movie or show folder resets its progress.

## Contributing / development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the dev setup (VS Code + BrightScript Language extension), project layout, architecture, testing, and debugging tips. Before sending a change, run `npm install` once and then `npm run check` (lint + unit tests, no Roku needed).

## License

[MIT](LICENSE): free to use, modify, and share.
