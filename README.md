# Couchmark

**An open-source media player for Roku TVs that remembers where you stopped.** It plays movies, shows and photos from a USB drive, picks up every episode exactly where you left off, and runs photo/video slideshows in the order the pictures were taken.

Everything runs on the TV. There is no server, account or phone app: plug in a USB drive, open Couchmark, and press play.

> **Status:** all phase-1 features are in place (milestones 1–5). Expect rough edges until it has been tested on more Roku models; please report issues.

## Why Couchmark?

I built Couchmark because I was very annoyed with Roku's own media player: it didn't remember where I was in my episodes on my USB stick. Couchmark fixes that. Its main job is to remember your place.

The name says what it does: **couch + bookmark**.

- **Couch:** you use it from the sofa with the Roku remote, and nothing else. No computer, server or app has to be running.
- **Bookmark:** it keeps your place in every movie and episode. **Continue Watching** takes you back with one press of OK, and the show page knows which episode comes next.

## Getting started

New to Couchmark? Follow these guides in order:

1. **[Set up your USB drive](docs/USB-SETUP.md):** how to name and arrange your folders so movies, shows and photos appear in the right place. This is the part that matters most.
2. **[Install Couchmark on your Roku](docs/INSTALL.md):** turn on developer mode, download the app, upload it from a browser. About ten minutes, no software needed.
3. **[Use Couchmark](docs/USER-GUIDE.md):** the home screen, shows, the player, slideshows, marking as watched, settings and debug logs.

### The USB drive in 30 seconds

```
Movies/
  The Matrix (1999)/
    The Matrix.mp4         ← every movie in its own folder
Shows/
  The Office/
    Season 1/
      S01E01 Pilot.mp4     ← show folder → season folder → episodes
Other/
  Summer 2025/
    IMG_0001.jpg           ← any folders of photos and videos
```

Folder names are the titles you see on the TV. A video placed directly in `Movies` or `Shows`, without its own folder, doesn't appear. The [USB guide](docs/USB-SETUP.md) has the full rules, artwork names, supported files and common mistakes. The `couchmark-usb-starter.zip` on the [Releases page](https://github.com/johncharbo95/couchmark/releases) gives you the empty folders, ready to fill.

### Installing in short

1. On the Roku remote press **Home ×3, Up ×2, Right, Left, Right, Left, Right** to turn on developer mode. Pick a password and note the IP address.
2. Download `couchmark-vX.Y.Z.zip` from the [Releases page](https://github.com/johncharbo95/couchmark/releases). Don't unzip it.
3. On a computer, open `http://<roku-ip>`, sign in as `rokudev`, click **Upload**, choose the zip and click **Install with zip**.

Step-by-step instructions, updating, and troubleshooting are in the [install guide](docs/INSTALL.md). To update later, upload the new zip the same way. Your watch progress is kept, as long as you don't click **Delete** on that page.

## Features

| Area | What it does | Status |
|---|---|---|
| USB detection | Finds every attached USB drive and merges their folders into one library. Rescans automatically when a drive is plugged in or removed. | ✅ |
| Home | Netflix-style rows: **Continue Watching** (one click resumes), Shows, Movies, and Browse. Uses folder artwork when available. | ✅ |
| Movies | Movie page with Resume / Play from beginning. Multi-file movies play as parts. Finished movies get a ✓. | ✅ |
| Shows | Show page with seasons and episodes side by side, "Continue S02E05 at 23:14", watched ✓ and partly-watched markers, and an "Up next" card in the last 10 seconds of each episode. | ✅ |
| Player | Netflix-style controls: 10-second skip, instant replay, previous/next episode, progress bar. | ✅ |
| Watched marks | Mark movies, episodes or whole seasons as watched / unwatched with the ✱ button. | ✅ |
| Other | Browse folders and play a slideshow of all photos and videos in a folder, ordered by the date they were taken. | ✅ |
| Files | Browse the USB drive exactly as it is, folder by folder, and play any video. A fallback for when a show or movie isn't recognized. | ✅ |
| Transitions | None, fade, slide, push, wipe, zoom, random, at three speeds. The next photo is preloaded, so there's never a black flash. | ✅ |
| Settings | Photo duration, transition type and speed, debug logs on/off, clear watch history. | ✅ |
| Debug logs | A daily log file on the USB drive, so you can see what happened when something goes wrong. | ✅ |

## Known limitations

- **No transcoding.** Roku plays files directly, so videos must use codecs your Roku supports (H.264/H.265 video with AAC/AC3 audio in MP4 or MKV is the safest choice). Unsupported files are skipped or show an error instead of crashing.
- **HEIC photos are not supported** (the default iPhone format). Convert them to JPEG, or set the iPhone to *Settings → Camera → Formats → Most Compatible*.
- **Subtitles are ignored** for now.
- **USB only.** Couchmark plays files from a USB drive; it doesn't stream from a computer or network share.
- **Slideshow dates** come from the photo's EXIF data or the video's MP4/MOV header. Photos edited or exported without EXIF, and MKV/TS/WebM videos, use the file's modified date, which may be when the file was copied rather than when it was taken.
- **Watch history is limited.** Roku gives each app about 16 KB of storage, so Couchmark stores progress compactly and forgets the least recently watched titles when space runs out.
- History is keyed by folder name, so renaming a movie or show folder resets its progress.

## Contributing / development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the dev setup (VS Code + BrightScript Language extension), project layout, architecture, testing, releases and debugging tips. Before sending a change, run `npm install` once and then `npm run check` (lint + unit tests, no Roku needed).

## License

[MIT](LICENSE): free to use, modify, and share.
