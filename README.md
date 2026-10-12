# couchmark
Open-source media player for Roku TVs. Plays movies, shows, and photos from a USB drive, remembers where you stopped, and runs dated photo/video slideshows with custom timing and transitions.

Everything runs on the TV. There is no server, account, or companion app: plug in a USB drive, open Couchmark, and press play.

> **Status:** early development. Milestones 1–3 (USB detection, Netflix-style home with Continue Watching, movies and shows with resume) are done. The features below marked *planned* arrive in the next milestones.

## Features

| Area | What it does | Status |
|---|---|---|
| USB detection | Finds every attached USB drive and merges their folders into one library. Rescans automatically when a drive is plugged in or removed. | ✅ |
| Home | Netflix-style rows: **Continue Watching** (one click resumes), Shows, Movies, and Browse. Uses folder artwork when available. | ✅ |
| Movies | Movie page with Resume / Play from beginning. Multi-file movies play as parts. Finished movies get a ✓. | ✅ |
| Shows | Show page with seasons and episodes side by side, "Continue S02E05 at 23:14", watched ✓ and partly-watched markers, and "Up next" when an episode ends. | ✅ |
| Player | Netflix-style controls: 10-second skip, instant replay, previous/next episode, progress bar. | ✅ |
| Other | Slideshow of all photos and videos in a folder, ordered by the date they were taken. | planned |
| Transitions | None, fade, slide, push, wipe, zoom, random. | planned |
| Settings | Photo duration, transition type and speed, clear watch history. | planned |

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

The controls hide after 5 seconds, or stay visible while paused. For movies with several parts, Previous/Next move between parts. Single-file movies have no Previous/Next buttons.

If no drive is found, plug one in. Couchmark notices it automatically, or you can press **OK** to look again.

## Known limitations

- **No transcoding.** Roku plays files directly, so videos must use codecs your Roku supports (H.264/H.265 video with AAC/AC3 audio in MP4 or MKV is the safest choice). Unsupported files are skipped or show an error instead of crashing.
- **HEIC photos are not supported** (the default iPhone format). Convert them to JPEG, or set the iPhone to *Settings → Camera → Formats → Most Compatible*.
- **Subtitles are ignored** for now.
- **Watch history is limited.** Roku gives each app about 16 KB of storage, so Couchmark stores progress compactly and forgets the least recently watched titles when space runs out.
- History is keyed by folder name, so renaming a movie or show folder resets its progress.

## Contributing / development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the dev setup (VS Code + BrightScript Language extension), project layout, architecture, and debugging tips.

## License

[MIT](LICENSE): free to use, modify, and share.
