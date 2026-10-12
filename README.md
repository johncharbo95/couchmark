# couchmark
Open-source media player for Roku TVs. Plays movies, shows, and photos from a USB drive, remembers where you stopped, and runs dated photo/video slideshows with custom timing and transitions.

Everything runs on the TV. There is no server, account, or companion app: plug in a USB drive, open Couchmark, and press play.

> **Status:** early development. Milestones 1–2 (USB detection, home screen, movies with resume) are done. The features below marked *planned* arrive in the next milestones.

## Features

| Area | What it does | Status |
|---|---|---|
| USB detection | Finds every attached USB drive and merges their folders into one library. Rescans automatically when a drive is plugged in or removed. | ✅ |
| Home | Movies, Shows, Other, and Settings tiles. Missing folders are dimmed, and selecting one explains what to create. | ✅ |
| Movies | Browse alphabetically, play, and resume where you stopped ("Resume from 1:02:14 / Start over"). Multi-file movies play as parts. Finished movies get a ✓. | ✅ |
| Shows | Show → Season → Episode. "Continue S02E05 at 23:14", watched ✓ and partly-watched markers, and "Up next" when an episode ends. | planned |
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

| Button | Action |
|---|---|
| Arrows / OK | Move and select |
| Back | Go back one screen (exits from the home screen). In the player, Back stops playback and remembers your position. |
| Play/Pause, ◀◀ ▶▶ | Control playback (Roku's standard player controls) |

### Movies

- Open **Movies** and pick a title. If you stopped partway through, choose **Resume from …** or **Start over**.
- A blue bar next to a title shows how far you got. A ✓ means you finished it (watched past 90%).
- If a movie folder holds several video files, they play one after another as parts. Between parts, an **Up next** card counts down 10 seconds (OK plays now, Back stops).

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
